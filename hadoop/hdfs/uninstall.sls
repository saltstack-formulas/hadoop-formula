{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}

hadoop-dfs-stopped:
  service.dead:
    - names: 
      - hadoop-namenode
      - hadoop-secondarynamenode
      - hadoop-zkfc
      - hadoop-datanode
      - hadoop-journalnode
    - enable: False

hadoop-dfs-services-removed:
  file.absent:
    - names:
      - /etc/systemd/system/hadoop-namenode.service
      - /etc/init.d/hadoop-namenode
      - /etc/systemd/system/hadoop-secondarynamenode.service
      - /etc/init.d/hadoop-secondarynamenode
      - /etc/systemd/system/hadoop-zkfc.service
      - /etc/init.d/hadoop-zkfc
      - /etc/systemd/system/hadoop-datanode.service
      - /etc/init.d/hadoop-datanode
      - /etc/systemd/system/hadoop-journalnode.service
      - /etc/init.d/hadoop-journalnode
    - require:
      - service: hadoop-dfs-stopped
{%- if grains.get('systemd') %}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: hadoop-dfs-services-removed
{%- endif %}

hadoop-dfs-files-removed:
  file.absent:
    - names:
      - {{ hadoop.alt_config }}/dfs.hosts.exclude
      - {{ hadoop.alt_config }}/dfs.hosts
      - {{ hadoop.alt_config }}/slaves
      - {{ hadoop.alt_config }}/masters
      - {{ hadoop.alt_config }}/hdfs-site.xml
      - {{ hadoop.alt_config }}/core-site.xml

{%- set hdfs_disks = hdfs.local_disks %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}

hadoop-dfs-data-removed:
  file.absent:
    - names:
{% for disk in hdfs_disks %}
      - {{ disk }}/hdfs
{% endfor %}
{%- if hdfs.tmp_dir != '/tmp' %}
      {{ hdfs.tmp_dir }}
{% endif %}
