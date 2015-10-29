# Install tutorial for Elkstack - Mac OS El Capitan running MAMP

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

Go to the ```logstash-2.0.0``` folder and create another file called ```logstash.conf``` with the following contents
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
Now go to the ```elasticsearch-2.0.0``` folder and edit ```config/elasticsearch.yml``` as follows:

```
# ---------------------------------- Cluster -----------------------------------
#
# Use a descriptive name for your cluster:
#
 cluster.name: DEMO
#
# ------------------------------------ Node ------------------------------------
#
# Use a descriptive name for the node:
#
 node.name: DEMO_Master
#
# Add custom attributes to the node:
#
# node.rack: r1
```

Next, from the terminal window ```cd /Users/(username)/developer/elk/logstash-2.0.0``` and install the elasticsearch java plugin
```
bin/plugin install --version 2.0.0 logstash-output-elasticsearch_java
```

Once this has been installed we need to start all the services as follows(a terminal tab is required for every folder):

```
cd /Users/(username)/developer/elk/elasticsearch-2.0.0
bin/elasticsearch
```

```
cd /Users/(username)/developer/elk/kibana-4.2.0-darwin-x64
bin/kibana
```

```
cd /Users/(username)/developer/elk/logstash-2.0.0
bin/logstash agent -f logstash.conf
```

Once these have started, go to ```http://localhost:5601/``` in your browser window.

If the set up has been done correctly, the Kibana settings page will allow you to configure an idex pattern, i.e. @timestamp and just click the green Create button
