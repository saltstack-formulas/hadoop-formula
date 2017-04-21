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

/etc/init.d/hadoop-namenode:
  file.managed:
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

{%- if hdfs.namenode_count == 1 %}
/etc/init.d/hadoop-secondarynamenode:
  file.managed:
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
{%- else %}
/etc/init.d/hadoop-zkfc:
  file.managed:
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
{% endif %}
{% endif %}

{% if hdfs.is_datanode %}
/etc/init.d/hadoop-datanode:
  file.managed:
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
{% endif %}

{% if hdfs.is_journalnode %}
/etc/init.d/hadoop-journalnode:
  file.managed:
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
