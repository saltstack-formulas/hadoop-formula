include:
  - hadoop.hdfs

{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/mapred/settings.sls' import mapred with context %}
{%- from 'hadoop/mapred/settings.sls' import mapred_site_dict with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}
{%- from 'hadoop/hdfs_mkdir_macro.sls' import hdfs_mkdir with context %}

{%- if hadoop.major_version|string() == '1' %}
{% do mapred_site_dict.update({
'mapred.job.tracker': { 'value': mapred.jobtracker_host + ':' + mapred.jobtracker_port|string },
'mapred.job.tracker.http.address': { 'value': mapred.jobtracker_host + ':' + mapred.jobtracker_http_port|string } }) %}
{% else %}
{% do mapred_site_dict.update({
'mapreduce.job.tracker': { 'value': mapred.jobtracker_host + ':' + mapred.jobtracker_port|string },
'mapreduce.job.tracker.http.address': { 'value': mapred.jobtracker_host + ':' + mapred.jobtracker_http_port|string } }) %}
{%- endif %}

# TODO: for what is ends up doing this state is way too complex
# TODO: no users implemented in settings yet
{%- set hadoop_users = hadoop.get('users', {}) %}

{% set username = 'mapred' %}
{% set uid = hadoop_users.get(username, '6002') %}
{{ hadoop_user(username, uid) }}

{% for disk in mapred.local_disks %}
{{ disk }}/mapred:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - mode: 775
    - makedirs: True
{% endfor %}

{{ hadoop['alt_config'] }}/mapred-site.xml:
  file.managed:
    - source: salt://hadoop/conf/mapred-site.xml
    - template: jinja
    - mode: 644
    - context:
      mapred_disks:
{%- for mr_disk in mapred.local_disks %}
        - {{ mr_disk }}
{%- endfor %}
      major: {{ hadoop.major_version }}
      mapred_dict:
{%- for k, v in mapred_site_dict.items() %}
        {{ k }}:
{%- for attr, val in v.items() %}
          {{ attr }}: {{ val }}
{%- endfor %}
{%- endfor %}

# create the /tmp directory

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}
# hadoop 1 apparently cannot set the sticky bit
{%- if hadoop.major_version == '2' %}
{{ hdfs_mkdir('/tmp', 'hdfs', None, 1777, hadoop.dfs_cmd) }}
{%- else %}
{{ hdfs_mkdir('/tmp', 'hdfs', None, 777, hadoop.dfs_cmd) }}
{%- endif %}
{% endif %}

{%- if 'hadoop_master' in salt['grains.get']('roles', []) and hadoop.major_version == '2' %}

# add mr-history directories for Hadoop 2

{{ hdfs_mkdir(mapred.history_dir, username, username, 755, hadoop.dfs_cmd) }}
{{ hdfs_mkdir(mapred.history_intermediate_done_dir, username, username, 1777, hadoop.dfs_cmd) }}
{{ hdfs_mkdir(mapred.history_done_dir, username, username, 1777, hadoop.dfs_cmd) }}

/etc/init.d/hadoop-historyserver:
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
      hadoop_svc: historyserver
      hadoop_user: mapred
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}

hadoop-historyserver:
  service:
    - running
    - enable: True

{% endif %}

# Hadoop 1 only - provision either job- or tasktracker

{%- if hadoop['major_version'] == '1' %}

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}
/etc/init.d/hadoop-jobtracker:
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
      hadoop_svc: jobtracker
      hadoop_user: mapred
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}

hadoop-jobtracker:
  service:
    - running
    - enable: True

{%- elif 'hadoop_slave' in salt['grains.get']('roles', []) %}

/etc/init.d/hadoop-tasktracker:
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
      hadoop_svc: tasktracker
      hadoop_user: mapred
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}

hadoop-tasktracker:
  service:
    - running
    - enable: True

{%- endif %}
{%- endif %}
