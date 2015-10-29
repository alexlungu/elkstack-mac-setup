# elkstack-mac-setup

This is a set of instructions to quickly setup the Elk Stack on Mac OS El Capitan running MAMP

Quick Start

1. Go to 
```
https://www.elastic.co/downloads
```

and download Elasticsearch, Logstash and Kibana

At the time of writing this small tutorial the following versions were downloaded

```
elasticsearch-2.0.0 - https://download.elasticsearch.org/elasticsearch/release/org/elasticsearch/distribution/zip/elasticsearch/2.0.0/elasticsearch-2.0.0.zip
kibana-4.2.0-darwin-x64 - https://download.elastic.co/kibana/kibana/kibana-4.2.0-darwin-x64.tar.gz
logstash-2.0.0 - https://download.elastic.co/logstash/logstash/logstash-2.0.0.zip
```

For ease of access my MAMP install points to a Developer folder
```
/Users/(username)/Developer
```

Create another folder in Developer called "elk" and paste the contents of the zip files previously downloaded
```
pwd: /Users/(username)/Developer/elk
ls: elasticsearch-2.0.0     kibana-4.2.0-darwin-x64   logstash-2.0.0
```

Go to the logstash-2.0.0 folder and create another file called ```logstash.conf``` with the following contents
```
input {
    file {
        path => "/Applications/MAMP/logs/apache_access.log"
       type => "apache"
    }
}

filter {
   if [type] == "apache" {

       grok {
           match => [ "message", "%{COMBINEDAPACHELOG}" ]
       }

       date {
           match => [ "timestamp", "dd/MMM/YYYY:HH:mm:ss Z" ]
       }
   }
}

output {
    elasticsearch_java {
       cluster => "DEMO"
       node_name => "logstash"
       network_host => "localhost:9200"

    }
}
```

