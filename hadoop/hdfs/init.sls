include:
  - hadoop

{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}
# TODO: no users implemented in settings yet
{%- set hadoop_users = hadoop.get('users', {}) %}
{%- set all_roles    = salt['grains.get']('roles', []) %}

{%- set username = 'hdfs' %}
{% set uid = hadoop_users.get(username, '6001') %}
{{ hadoop_user(username, uid) }}
# every node can advertise any JBOD drives to the framework by setting salt grains
{%- set hdfs_disks = salt['grains.get']('hdfs_data_disks', ['/data']) %}

{% for disk in hdfs_disks %}
{{ disk }}/hdfs:
  file.directory:
    - user: root
    - group: root
    - makedirs: True
{% if 'hadoop_master' in all_roles %}
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

{% if 'hadoop_slave' in all_roles %}

{{ disk }}/hdfs/dn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{% endif %}

{% endfor %}

{{ hadoop['alt_config'] }}/core-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/core-site.xml
    - template: jinja
    - context:
      hdfs_disks: {{ hdfs_disks }}
      hadoop: {{ hadoop }}
      namenode_host: {{ hadoop['namenode_host'] }}

{{ hadoop['alt_config'] }}/hdfs-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/hdfs-site.xml
    - template: jinja
    - context:
      hdfs_disks: {{ hdfs_disks }}
      hadoop: {{ hadoop }}
      namenode_host: {{ hadoop['namenode_host'] }}
      major: {{ hadoop['major_version'] }}
      hdfs_replicas: {{ hadoop.hdfs_replicas }}

{{ hadoop['alt_config'] }}/masters:
  file.managed:
    - source: salt://hadoop/conf/hdfs/masters
    - template: jinja
    - context:
      namenode_host: {{ hadoop['namenode_host'] }}

{{ hadoop['alt_config'] }}/slaves:
  file.managed:
    - source: salt://hadoop/conf/hdfs/slaves
    - template: jinja

{%- if 'hadoop_master' in all_roles %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}

format-namenode:
  cmd.run:
{%- if hadoop['major_version'] == '1' %}
    - name: {{ hadoop['alt_home'] }}/bin/hadoop namenode -format -force
{%- else %}
    - name: {{ hadoop['alt_home'] }}/bin/hdfs namenode -format
{% endif %}
    - user: hdfs
    - unless: test -d {{ test_folder }}

/etc/init.d/hadoop-namenode:
  file.managed:
{%- if grains.os == 'Ubuntu' %}
    - source: salt://hadoop/files/hadoop.init.d.ubuntu.jinja
{%- else %}
    - source: salt://hadoop/files/hadoop.init.d.jinja
{%- endif %}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: namenode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}

/etc/init.d/hadoop-secondarynamenode:
  file.managed:
{%- if grains.os == 'Ubuntu' %}
    - source: salt://hadoop/files/hadoop.init.d.ubuntu.jinja
{%- else %}
    - source: salt://hadoop/files/hadoop.init.d.jinja
{%- endif %}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: secondarynamenode
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
{% endif %}

{%- if 'hadoop_slave' in all_roles %}
/etc/init.d/hadoop-datanode:
  file.managed:
{%- if grains.os == 'Ubuntu' %}
    - source: salt://hadoop/files/hadoop.init.d.ubuntu.jinja
{%- else %}
    - source: salt://hadoop/files/hadoop.init.d.jinja
{%- endif %}
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

{%- if 'hadoop_master' in all_roles or 'hadoop_slave' in all_roles %}

hdfs-services:
  service:
    - running
    - enable: True
    - names:
{%- if 'hadoop_master' in all_roles %}
      - hadoop-secondarynamenode
      - hadoop-namenode
{% endif %}
{%- if 'hadoop_slave' in all_roles %}
      - hadoop-datanode
{% endif %}

{% endif %}