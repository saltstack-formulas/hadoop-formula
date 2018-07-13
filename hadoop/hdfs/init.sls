{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}

{%- set username = 'hdfs' %}
{%- set uid = hadoop.users[username] %}

{{ hadoop_user(username, uid) }}

# every node can advertise any JBOD drives to the framework by setting the hdfs_data_disk grain
{%- set hdfs_disks = hdfs.local_disks %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}

{% for disk in hdfs_disks %}
{{ disk }}/hdfs:
  file.directory:
    - user: root
    - group: root
    - makedirs: True
{% if hdfs.is_namenode %}
{{ disk }}/hdfs/nn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{{ disk }}/hdfs/snn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{% endif %}

{%- if hdfs.tmp_dir != '/tmp' %}
{{ hdfs.tmp_dir }}:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
    - mode: '1775'
{% endif %}


{%- if hdfs.is_datanode %}
{{ disk }}/hdfs/dn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{%- endif %}

{%- if hdfs.is_journalnode %}
{{ disk }}/hdfs/journal:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{%- endif %}

{% endfor %}

{{ hadoop.alt_config }}/core-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/core-site.xml
    - template: jinja
    - mode: 644

{{ hadoop.alt_config }}/hdfs-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/hdfs-site.xml
    - template: jinja
    - mode: 644

{{ hadoop.alt_config }}/masters:
  file.managed:
    - mode: 644
    - contents: {{ hdfs.namenode_host }}

{{ hadoop.alt_config }}/slaves:
  file.managed:
    - mode: 644
    - contents: |
{%- for slave in hdfs.datanode_hosts %}
        {{ slave }}
{%- endfor %}

{{ hadoop.alt_config }}/dfs.hosts:
  file.managed:
    - mode: 644
    - contents: |
{%- for slave in hdfs.datanode_hosts %}
        {{ slave }}
{%- endfor %}

{{ hadoop.alt_config }}/dfs.hosts.exclude:
  file.managed

{% if hdfs.is_namenode %}

{%- if hdfs.namenode_count == 1 %}
format-namenode:
  cmd.run:
{%- if hadoop.major_version|string() == '1' %}
    - name: {{ hadoop.alt_home }}/bin/hadoop namenode -format -force
{%- else %}
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -format
{% endif %}
    - user: hdfs
    - unless: test -d {{ test_folder }}
{%- endif %}

hadoop-namenode-service:
  file.managed:
{%- if grains.get('systemd') %}
    - name: /etc/systemd/system/hadoop-namenode.service
{% else %}
    - name: /etc/init.d/hadoop-namenode
{% endif %}
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: namenode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
{%- if grains.get('systemd') %}
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: hadoop-namenode-service
{% if hdfs.is_datanode or hdfs.is_journalnode %}
    - watch_in:
      - service: hdfs-services
{% endif %}
{% endif %}

{%- if hdfs.namenode_count == 1 %}
hadoop-secondarynamenode-service:
  file.managed:
{%- if grains.get('systemd') %}
    - name: /etc/systemd/system/hadoop-secondarynamenode.service
{% else %}
    - name: /etc/init.d/hadoop-secondarynamenode
{% endif %}
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: secondarynamenode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
{%- if grains.get('systemd') %}
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: hadoop-secondarynamenode-service
    - watch_in:
      - service: hdfs-nn-services
{% endif %}
{%- else %}
hadoop-zkfc-service:
  file.managed:
{%- if grains.get('systemd') %}
    - name: /etc/systemd/system/hadoop-zkfc.service
{% else %}
    - name: /etc/init.d/hadoop-zkfc
{% endif %}
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: zkfc
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
{%- if grains.get('systemd') %}
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: hadoop-zkfc-service
{% endif %}
{% endif %}
{% endif %}

{% if hdfs.is_datanode %}

hadoop-datanode-service:
  file.managed:
{%- if grains.get('systemd') %}
    - name: /etc/systemd/system/hadoop-datanode.service
{% else %}
    - name: /etc/init.d/hadoop-datanode
{% endif %}
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: datanode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
{%- if grains.get('systemd') %}
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: hadoop-datanode-service
    - watch_in:
      - service: hdfs-services
{% endif %}
{% endif %}

{% if hdfs.is_journalnode %}
hadoop-journalnode-service:
  file.managed:
{%- if grains.get('systemd') %}
    - name: /etc/systemd/system/hadoop-journalnode.service
{% else %}
    - name: /etc/init.d/hadoop-journalnode
{% endif %}
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: journalnode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
{%- if grains.get('systemd') %}
  module.wait:
    - name: service.systemctl_reload
    - watch:
      - file: hadoop-journalnode-service
    - watch_in:
      - service: hdfs-services
{% endif %}
{% endif %}

{% if hdfs.is_namenode and hdfs.namenode_count == 1 %}
hdfs-nn-services:
  service.running:
    - enable: True
    - names:
      - hadoop-secondarynamenode
      - hadoop-namenode
{%- if hdfs.restart_on_config_change == True %}
    - watch:
      - file: {{ hadoop.alt_config }}/core-site.xml
      - file: {{ hadoop.alt_config }}/hdfs-site.xml
{%- endif %}
{%- endif %}

{% if hdfs.is_datanode or hdfs.is_journalnode %}
hdfs-services:
  service.running:
    - enable: True
    - names:
{%- if hdfs.is_datanode %}
      - hadoop-datanode
{%- endif %}
{%- if hdfs.is_journalnode %}
      - hadoop-journalnode
{%- endif %}
{%- if hdfs.restart_on_config_change == True %}
    - watch:
      - file: {{ hadoop.alt_config }}/core-site.xml
      - file: {{ hadoop.alt_config }}/hdfs-site.xml
{%- endif %}
{%- endif %}
