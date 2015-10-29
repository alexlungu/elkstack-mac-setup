Gem::Specification.new do |s|
  s.name            = 'logstash-output-elasticsearch_java'
  s.version         = '2.0.0'
  s.licenses        = ['apache-2.0']
  s.summary         = "Logstash Output to Elasticsearch using Java node/transport client"
  s.description     = "Output events to elasticsearch using the java client"
  s.authors         = ["Elastic"]
  s.email           = 'info@elastic.co'
  s.homepage        = "http://logstash.net/"
  s.require_paths = ["lib"]

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']

  # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency 'concurrent-ruby'
  s.add_runtime_dependency 'elasticsearch', ['>= 1.0.13', '~> 1.0']
  s.add_runtime_dependency 'stud', ['>= 0.0.17', '~> 0.0']
  s.add_runtime_dependency 'cabin', ['~> 0.6']
  s.add_runtime_dependency "logstash-core", ">= 2.0.0.beta2", "< 3.0.0"

  s.add_development_dependency 'ftw', '~> 0.0.42'
  s.add_development_dependency 'logstash-input-generator'
  s.add_development_dependency 'logstash-devutils'
  s.add_development_dependency 'longshoreman'
end
