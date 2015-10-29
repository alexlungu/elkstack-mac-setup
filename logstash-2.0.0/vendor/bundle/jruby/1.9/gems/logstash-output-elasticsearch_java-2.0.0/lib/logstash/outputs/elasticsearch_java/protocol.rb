require "cabin"
require "base64"
require 'logstash-output-elasticsearch_java_jars.rb'
require 'logstash/outputs/elasticsearch_java'

module LogStash
  module Outputs
    module ElasticSearchJavaPlugins
      module Protocols
        class Base
          private
          def initialize(options={})
            # host(s), port, cluster
            @logger = Cabin::Channel.get
          end

          def template_install(name, template, force=false)
            if template_exists?(name) && !force
              @logger.debug("Found existing Elasticsearch template. Skipping template management", :name => name)
              return
            end
            template_put(name, template)
          end

          # Do a bulk request with the given actions.
          #
          # 'actions' is expected to be an array of bulk requests as string json
          # values.
          #
          # Each 'action' becomes a single line in the bulk api call. For more
          # details on the format of each.
          def bulk(actions)
            raise NotImplemented, "You must implement this yourself"
            # bulk([
            # '{ "index" : { "_index" : "test", "_type" : "type1", "_id" : "1" } }',
            # '{ "field1" : "value1" }'
            #])
          end

          public(:initialize, :template_install)
        end

        class NodeClient < Base
          CLIENT_MUTEX = Mutex.new

          def self.get_client(settings)
            CLIENT_MUTEX.synchronize {
              if @client
                @client
              else
                nodebuilder = org.elasticsearch.node.NodeBuilder.nodeBuilder
                @client = nodebuilder.settings(settings.build).node().client()
              end
            }
          end

          def self.clear_client()
            CLIENT_MUTEX.synchronize {
              @client = null
            }
          end

          private

          DEFAULT_OPTIONS = {
            :port => 9300,
          }

          def initialize(options={})
            super
            require "java"
            @options = DEFAULT_OPTIONS.merge(options)
            setup(@options)
          end # def initialize

          def settings
            return @settings
          end

          def client
            self.class.get_client(settings)
          end

          def setup(options={})
            @settings = org.elasticsearch.common.settings.Settings.settingsBuilder()
            if options[:hosts]
              @settings.put("discovery.zen.ping.multicast.enabled", false)
              @settings.put("discovery.zen.ping.unicast.hosts", NodeClient.hosts(options))
            end

            @settings.put("node.client", true)
            @settings.put("http.enabled", false)
            @settings.put("path.home", Dir.pwd)

            if options[:client_settings]
              options[:client_settings].each do |key, value|
                @settings.put(key, value)
              end
            end

            return @settings
          end

          def self.hosts(options)
            # http://www.elasticsearch.org/guide/reference/modules/discovery/zen/
            result = Array.new
            if options[:hosts].class == Array
              options[:hosts].each do |host|
                if host.to_s =~ /^.+:.+$/
                  # For host in format: host:port, ignore options[:port]
                  result << host
                else
                  if options[:port].to_s =~ /^\d+-\d+$/
                    # port ranges are 'host[port1-port2]'
                    result << Range.new(*options[:port].split("-")).collect { |p| "#{host}:#{p}" }
                  else
                    result << "#{host}:#{options[:port]}"
                  end
                end
              end
            else
              if options[:hosts].to_s =~ /^.+:.+$/
                # For host in format: host:port, ignore options[:port]
                result << options[:hosts]
              else
                if options[:port].to_s =~ /^\d+-\d+$/
                  # port ranges are 'host[port1-port2]' according to
                  # http://www.elasticsearch.org/guide/reference/modules/discovery/zen/
                  # However, it seems to only query the first port.
                  # So generate our own list of unicast hosts to scan.
                  range = Range.new(*options[:port].split("-"))
                  result << range.collect { |p| "#{options[:hosts]}:#{p}" }
                else
                  result << "#{options[:hosts]}:#{options[:port]}"
                end
              end
            end
            result.flatten.join(",")
          end

          def self.normalize_bulk_response(bulk_response)
            # TODO(talevy): parse item response objects to retrieve correct 200 (OK) or 201(created) status codes
            if bulk_response.has_failures()
              {"errors" => true,
               "statuses" => bulk_response.map { |i| (i.is_failed && i.get_failure.get_status.get_status) || 200 }}
            else
              {"errors" => false}
            end
          end

          def bulk(actions)
            # Actions an array of [ action, action_metadata, source ]
            prep = client.prepareBulk
            actions.each do |action, args, source|
              prep.add(build_request(action, args, source))
            end
            response = prep.execute.actionGet()

            self.class.normalize_bulk_response(response)
          end # def bulk

          def build_request(action, args, source)
            case action
              when "index"
                request = org.elasticsearch.action.index.IndexRequest.new(args[:_index])
                request.id(args[:_id]) if args[:_id]
                request.routing(args[:_routing]) if args[:_routing]
                request.source(source)
              when "delete"
                request = org.elasticsearch.action.delete.DeleteRequest.new(args[:_index])
                request.id(args[:_id])
                request.routing(args[:_routing]) if args[:_routing]
              when "create"
                request = org.elasticsearch.action.index.IndexRequest.new(args[:_index])
                request.id(args[:_id]) if args[:_id]
                request.routing(args[:_routing]) if args[:_routing]
                request.source(source)
                request.opType("create")
              when "create_unless_exists"
                unless args[:_id].nil?
                  request = org.elasticsearch.action.index.IndexRequest.new(args[:_index])
                  request.id(args[:_id])
                  request.routing(args[:_routing]) if args[:_routing]
                  request.source(source)
                  request.opType("create")
                else
                  raise(LogStash::ConfigurationError, "Specifying action => 'create_unless_exists' without a document '_id' is not supported.")
                end
              when "update"
                unless args[:_id].nil?
                  request = org.elasticsearch.action.update.UpdateRequest.new(args[:_index], args[:_type], args[:_id])
                  request.routing(args[:_routing]) if args[:_routing]
                  request.doc(source)
                  if @options[:doc_as_upsert]
                    request.docAsUpsert(true)
                  else
                    request.upsert(args[:_upsert]) if args[:_upsert]
                  end
                else
                  raise(LogStash::ConfigurationError, "Specifying action => 'update' without a document '_id' is not supported.")
                end
              else
                raise(LogStash::ConfigurationError, "action => '#{action_name}' is not currently supported.")
            end # case action

            request.type(args[:_type]) if args[:_type]
            return request
          end # def build_request

          def template_exists?(name)
            return !client.admin.indices.
              prepareGetTemplates(name).
              execute().
              actionGet().
              getIndexTemplates().
              isEmpty
          end # def template_exists?

          def template_put(name, template)
            response = client.admin.indices.
              preparePutTemplate(name).
              setSource(LogStash::Json.dump(template)).
              execute().
              actionGet()

            raise "Could not index template!" unless response.isAcknowledged
          end # template_put

          public(:initialize, :bulk)
        end # class NodeClient

        class TransportClient < NodeClient
          def client
            return @client if @client
            @client = build_client(@options)
            return @client
          end


          private
          def build_client(options)
            client = org.elasticsearch.client.transport.TransportClient.
              builder().
              settings((settings.build)).
              build()

            options[:hosts].each do |host|
              matches = host.match /(.+)(?:.*)/

              inet_addr = java.net.InetAddress.getByName(matches[1])
              port = (matches[2] || options[:port]).to_i
              client.addTransportAddress(
                org.elasticsearch.common.transport.InetSocketTransportAddress.new(
                  inet_addr, port
                )
              )
            end

            return client
          end
        end
      end
    end
  end
end