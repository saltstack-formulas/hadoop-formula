{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'zookeeper/settings.sls' import zk with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}
{%- set username = 'hdfs' %}
{%- set hdfs_disks = hdfs.local_disks %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}

{%- if hdfs.is_primary_namenode or hdfs.is_secondary_namenode %}
{%- if grains['os_family'] == 'RedHat' %}
'nmap-ncat':
   pkg.installed
{%- elif grains['os_family'] == 'Debian' %}
'netcat-traditional':
   pkg.installed
{%- endif %}
{%- endif %}

{%- if hdfs.is_primary_namenode %}

format-namenode:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -format
    - user: hdfs
    - unless: test -d {{ test_folder }}

format-zookeeper:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs zkfc -formatZK
    - user: hdfs
    - unless: service status hadoop-zkfc
    - onlyif: echo 'ls /hadoop-ha' | {{zk.alt_home}}/bin/zkCli.sh -server {{zk.connection_string}} 2>&1 | grep 'Node does not exist'

{%- elif hdfs.is_secondary_namenode %}
  # orchestration has to ensure that this part runs after the primary has successfully finished

bootstrap-secondary-namenode:
  cmd.run:
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -bootstrapStandby
    - user: hdfs
    - unless: test -d {{ test_folder }}

{%- endif %}

{%- if hdfs.is_primary_namenode or hdfs.is_secondary_namenode %}

hdfs-services:
  service.running:
    - enable: True
    - names:
      - hadoop-namenode
      - hadoop-zkfc

{% endif %}
