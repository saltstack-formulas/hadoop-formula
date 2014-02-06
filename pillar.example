# java_home: /usr/lib/java

hadoop:
  version: apache-1.2.1 # ['apache-1.2.1', 'apache-2.2.0', 'hdp-1.3.0', 'hdp-2.2.0', 'cdh-4.5.0', 'cdh-4.5.0-mr1']
  users:
    hadoop: 6000
    hdfs: 6001
    mapred: 6002
    yarn: 6003
  config:
    directory: /etc/hadoop/conf
    core-site:
      io.native.lib.available:
        value: true
      io.file.buffer.size:
        value: 65536
      fs.trash.interval:
        value: 60

hdfs:
  config:
    namenode_port: 8020
    namenode_http_port: 50070
    secondarynamenode_http_port: 50090
    # the number of hdfs replicas is normally auto-configured for you by the hadoop-formula
    # according to the number of available datanodes
    # replication: 1
    hdfs-site:
      dfs.permission:
        value: false
      dfs.durable.sync:
        value: true
      dfs.datanode.synconclose:
        value: true

mapred:
  config:
    jobtracker_port: 9001
    jobtracker_http_port: 50030
    jobhistory_port: 10020
    jobhistory_webapp_port: 19888
    history_dir: /mr-history
    mapred-site: 
      mapred.map.memory.mb:
        value: 1536
      mapred.map.java.opts:
        value: -Xmx1024M
      mapred.reduce.memory.mb:
        value: 3072
      mapred.reduce.java.opts:
        value: -Xmx1024m
      mapred.task.io.sort.mb:
        value: 512
      mapred.task.io.sort.factor:
        value: 100
      mapred.reduce.shuffle.parallelcopies:
        value: 50

yarn:
  config:
    yarn-site:
      yarn.nodemanager.aux-services:
        value: mapreduce_shuffle
      yarn.nodemanager.aux-services.mapreduce.shuffle.class:
        value: org.apache.hadoop.mapred.ShuffleHandler
      yarn.resourcemanager.scheduler.class:
        value: org.apache.hadoop.yarn.server.resourcemanager.scheduler.capacity.CapacityScheduler

