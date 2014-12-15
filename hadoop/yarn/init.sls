{%- from "hadoop/settings.sls" import hadoop with context %}
{%- from "hadoop/yarn/settings.sls" import yarn with context %}
{%- from "hadoop/mapred/settings.sls" import mapred with context %}
{%- from "hadoop/user_macro.sls" import hadoop_user with context %}
{%- from 'hadoop/hdfs_mkdir_macro.sls' import hdfs_mkdir with context %}

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

{{ hadoop.alt_config }}/container-executor.cfg:
  file.managed:
    - source: salt://hadoop/conf/yarn/container-executor.cfg
    - mode: 644
    - user: root
    - group: root
    - template: jinja
    - context:
      local_disks: 
{%- for disk in yarn.local_disks %}
        - {{ disk }}/yarn/local
{%- endfor %}
      local_log_disk: {{ yarn.first_local_disk }}/yarn/log
      banned_users_list: {{ yarn.banned_users|join(',') }}

# restore the special permissions of the linux container executor
fix-executor-group:
  cmd.run:
    - user: root
    - names:
      - chown root {{hadoop.alt_home}}/bin/container-executor
      - chgrp {{username}} {{hadoop.alt_home}}/bin/container-executor

fix-executor-permissions:
  cmd.run:
    - user: root
    - name: chmod 06050 {{hadoop.alt_home}}/bin/container-executor
    - require: 
      - cmd: fix-executor-group

{{ hadoop.alt_config }}/yarn-site.xml:
  file.managed:
    - source: salt://hadoop/conf/yarn/yarn-site.xml
    - mode: 644
    - user: root
    - template: jinja

{{ hadoop.alt_config }}/capacity-scheduler.xml:
  file.managed:
    - source: salt://hadoop/conf/yarn/capacity-scheduler.xml
    - mode: 644
    - user: root
    - template: jinja

{% if hdfs.is_namenode %}

# add mr-history directories for Hadoop 2
{%- set yarn_site = yarn.config_yarn_site %}
{%- set rald = yarn_site.get('yarn.nodemanager.remote-app-log-dir', '/app-logs') %}

{{ hdfs_mkdir(mapred.history_dir, username, username, 755, hadoop.dfs_cmd) }}
{{ hdfs_mkdir(mapred.history_intermediate_done_dir, username, username, 1777, hadoop.dfs_cmd) }}
{{ hdfs_mkdir(mapred.history_done_dir, username, username, 1777, hadoop.dfs_cmd) }}
{{ hdfs_mkdir(rald, username, 'hadoop', 1777, hadoop.dfs_cmd) }}

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

hadoop-historyserver:
  service.running:
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
  service.running:
    - enable: True
{% endif %}

{% if hdfs.is_datanode %}

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
  service.running:
    - enable: True
{% endif %}

{%- endif %}
