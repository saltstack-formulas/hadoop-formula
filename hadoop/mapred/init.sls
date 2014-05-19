{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/mapred/settings.sls' import mapred with context %}
{%- from 'hadoop/user_macro.sls' import hadoop_user with context %}
{%- from 'hadoop/hdfs_mkdir_macro.sls' import hdfs_mkdir with context %}

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
    - source: salt://hadoop/conf/mapred/mapred-site.xml
    - template: jinja
    - mode: 644

{{ hadoop['alt_config'] }}/taskcontroller.cfg:
  file.managed:
    - source: salt://hadoop/conf/mapred/taskcontroller.cfg
    - template: jinja
    - mode: 644

# create the /tmp directory

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}
# hadoop 1 apparently cannot set the sticky bit
{%- if hadoop.major_version == '2' %}
{{ hdfs_mkdir('/tmp', 'hdfs', None, 1777, hadoop.dfs_cmd) }}
{%- else %}
{{ hdfs_mkdir('/tmp', 'hdfs', None, 777, hadoop.dfs_cmd) }}
{%- endif %}
{% endif %}

# Hadoop 1 only - provision either job- or tasktracker

{%- if hadoop['major_version'] == '1' %}

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}
/etc/init.d/hadoop-jobtracker:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
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
{%- endif %}

{%- if 'hadoop_slave' in salt['grains.get']('roles', []) %}

/etc/init.d/hadoop-tasktracker:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
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
