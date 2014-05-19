{%- from "hadoop/settings.sls" import hadoop with context %}
{%- from "hadoop/yarn/settings.sls" import yarn with context %}
{%- from "hadoop/mapred/settings.sls" import mapred with context %}
{%- from "hadoop/user_macro.sls" import hadoop_user with context %}
{%- from 'hadoop/hdfs_mkdir_macro.sls' import hdfs_mkdir with context %}
{%- set all_roles    = salt['grains.get']('roles', []) %}

# TODO: no users implemented in settings yet
{%- set hadoop_users = hadoop.get('users', {}) %}

{%- if hadoop['major_version'] == '2' %}

{% set username = 'yarn' %}
{% set uid = hadoop_users.get(username, '6003') %}
{{ hadoop_user(username, uid) }}

{% for disk in yarn.local_disks %}
{{ disk }}/yarn:
  file.directory:
    - user: root
    - group: root
    - makedirs: True
{{ disk }}/yarn/local:
  file.directory:
    - user: yarn
    - group: hadoop
    - require:
      - file: {{ disk }}/yarn
{% endfor %}

{{ yarn.first_local_disk }}/yarn/logs:
  file.directory:
    - user: yarn
    - group: hadoop
    - require:
      - file: {{ yarn.first_local_disk }}/yarn

{{ hadoop.alt_config }}/yarn-site.xml:
  file.managed:
    - source: salt://hadoop/conf/yarn/yarn-site.xml
    - mode: 644
    - user: root
    - template: jinja

{{ hadoop.alt_config }}/container-executor.cfg:
  file.managed:
    - source: salt://hadoop/conf/yarn/container-executor.cfg
    - mode: 644
    - user: root
    - group: root
    - template: jinja

{{ hadoop.alt_config }}/capacity-scheduler.xml:
  file.copy:
    - source: {{ hadoop['real_config_dist'] }}/capacity-scheduler.xml
    - user: root
    - group: root
    - mode: 644

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}

# add mr-history directories for Hadoop 2

{{ hdfs_mkdir(mapred.history_dir, username, username, 755, hadoop.dfs_cmd) }}
{{ hdfs_mkdir(mapred.history_intermediate_done_dir, username, username, 1777, hadoop.dfs_cmd) }}
{{ hdfs_mkdir(mapred.history_done_dir, username, username, 1777, hadoop.dfs_cmd) }}

/etc/init.d/hadoop-historyserver:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: historyserver
      hadoop_user: hdfs
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}
      node_roles: {{ all_roles }}

hadoop-historyserver:
  service:
    - running
    - enable: True

/etc/init.d/hadoop-resourcemanager:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: resourcemanager
      hadoop_user: yarn
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}

hadoop-resourcemanager:
  service:
    - running
    - enable: True
{% endif %}

{%- if 'hadoop_slave' in salt['grains.get']('roles', []) %}

/etc/init.d/hadoop-nodemanager:
  file.managed:
    - source: salt://hadoop/files/{{ hadoop.initscript }}
    - user: root
    - group: root
    - mode: '755'
    - template: jinja
    - context:
      hadoop_svc: nodemanager
      hadoop_user: yarn
      hadoop_major: {{ hadoop.major_version }}
      hadoop_home: {{ hadoop.alt_home }}

hadoop-nodemanager:
  service:
    - running
    - enable: True
{% endif %}

{%- endif %}