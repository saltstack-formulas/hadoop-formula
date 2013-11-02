export JAVA_HOME={{ java_home }}
export HADOOP_PREFIX={{ hadoop_home }}
export HADOOP_CONF_DIR={{ hadoop_config }}
export PATH=$HADOOP_PREFIX/bin:$HADOOP_PREFIX/sbin:${JAVA_HOME}/bin:$PATH

export HADOOP_HEAPSIZE=1024
export HADOOP_NAMENODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_NAMENODE_OPTS"
export HADOOP_SECONDARYNAMENODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_SECONDARYNAMENODE_OPTS"
export HADOOP_DATANODE_OPTS="-Dcom.sun.management.jmxremote $HADOOP_DATANODE_OPTS"
export HADOOP_BALANCER_OPTS="-Dcom.sun.management.jmxremote $HADOOP_BALANCER_OPTS"
export HADOOP_JOBTRACKER_OPTS="-Dcom.sun.management.jmxremote $HADOOP_JOBTRACKER_OPTS"

export HADOOP_USER=hadoop
export HDFS_USER=hdfs
export MAPRED_USER=mapred
export YARN_USER=yarn

{%- set logs = '/var/log/hadoop' %}
{%- set pids = '/var/run/hadoop' %}

export HADOOP_LOG_DIR={{ logs }}
export HDFS_LOG_DIR={{ logs }}/hdfs
export MAPRED_LOG_DIR={{ logs }}/mapred
export YARN_LOG_DIR={{ logs }}/yarn

export HADOOP_PID_DIR={{ pids }}
export HDFS_PID_DIR={{ pids }}/hdfs
export MAPRED_PID_DIR={{ pids }}/mapred
export YARN_PID_DIR={{ pids }}/yarn
