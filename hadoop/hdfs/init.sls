{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}
# TODO: no users implemented in settings yet
{%- set hadoop_users = hadoop.get('users', {}) %}
{%- set all_roles    = salt['grains.get']('roles', []) %}
{%- set username = 'hdfs' %}
{%- set uid = hadoop_users.get(username, '6001') %}

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

{%- if hdfs.tmp_dir != '/tmp' %}
{{ hdfs.tmp_dir }}:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
    - mode: '1775'
{% endif %}

{% if 'hadoop_slave' in all_roles %}

{{ disk }}/hdfs/dn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{% endif %}

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

{%- if 'hadoop_master' in all_roles %}

format-namenode:
  cmd.run:
{%- if hadoop.major_version|string() == '1' %}
    - name: {{ hadoop.alt_home }}/bin/hadoop namenode -format -force
{%- else %}
    - name: {{ hadoop.alt_home }}/bin/hdfs namenode -format
{% endif %}
    - user: hdfs
    - unless: test -d {{ test_folder }}

/etc/init.d/hadoop-namenode:
  file.managed:
{%- if grains.os_family == 'RedHat' %}
    - source: salt://hadoop/files/hadoop.init.d.jinja
{%- else %}
    - source: salt://hadoop/files/hadoop.init.d.ubuntu.jinja
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
{%- if grains.os_family == 'RedHat' %}
    - source: salt://hadoop/files/hadoop.init.d.jinja
{%- else %}
    - source: salt://hadoop/files/hadoop.init.d.ubuntu.jinja
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
{%- if grains.os_family == 'RedHat' %}
    - source: salt://hadoop/files/hadoop.init.d.jinja
{%- else %}
    - source: salt://hadoop/files/hadoop.init.d.ubuntu.jinja
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