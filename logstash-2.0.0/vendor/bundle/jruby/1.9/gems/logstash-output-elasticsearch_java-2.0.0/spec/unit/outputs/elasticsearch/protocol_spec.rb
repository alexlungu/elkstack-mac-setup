require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/elasticsearch_java/protocol"
require "java"

describe LogStash::Outputs::ElasticSearchJavaPlugins::Protocols::NodeClient do
  context "successful" do
    it "should map correctly" do
      index_response = org.elasticsearch.action.index.IndexResponse.new("my_index", "my_type", "my_id", 123, true)
      update_response = org.elasticsearch.action.update.UpdateResponse.new("my_index", "my_type", "my_id", 123, false)
      delete_response = org.elasticsearch.action.delete.DeleteResponse.new("my_index", "my_type", "my_id", 123, true)
      bulk_item_response_index = org.elasticsearch.action.bulk.BulkItemResponse.new(32, "index", index_response)
      bulk_item_response_update = org.elasticsearch.action.bulk.BulkItemResponse.new(32, "update", update_response)
      bulk_item_response_delete = org.elasticsearch.action.bulk.BulkItemResponse.new(32, "delete", delete_response)
      bulk_response = org.elasticsearch.action.bulk.BulkResponse.new([bulk_item_response_index, bulk_item_response_update, bulk_item_response_delete], 0)
      ret = LogStash::Outputs::ElasticSearchJavaPlugins::Protocols::NodeClient.normalize_bulk_response(bulk_response)
      insist { ret } == {"errors" => false}
    end
  end

  context "contains failures" do
    it "should map correctly" do
      failure = org.elasticsearch.action.bulk.BulkItemResponse::Failure.new("my_index", "my_type", "my_id", java.lang.IllegalArgumentException.new("bad_request"))
      bulk_item_response_index = org.elasticsearch.action.bulk.BulkItemResponse.new(32, "index", failure)
      bulk_item_response_update = org.elasticsearch.action.bulk.BulkItemResponse.new(32, "update", failure)
      bulk_item_response_delete = org.elasticsearch.action.bulk.BulkItemResponse.new(32, "delete", failure)
      bulk_response = org.elasticsearch.action.bulk.BulkResponse.new([bulk_item_response_index, bulk_item_response_update, bulk_item_response_delete], 0)
      actual = LogStash::Outputs::ElasticSearchJavaPlugins::Protocols::NodeClient.normalize_bulk_response(bulk_response)
      insist { actual } == {"errors" => true, "statuses" => [400, 400, 400]}
    end
  end
end