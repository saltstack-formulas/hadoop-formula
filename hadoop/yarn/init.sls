include:
  - hadoop.hdfs

{%- from "hadoop/map.jinja" import map with context %}
{%- from "hadoop/settings.sls" import hadoop with context %}
{%- from "hadoop/user_macro.sls" import hadoop_user with context %}
# TODO: no users implemented in settings yet
{%- set hadoop_users = hadoop.get('users', {}) %}
{%- set yarn = pillar.get('yarn', {}) %}

{%- if hadoop['major_version'] == '2' %}

{% set yarn_disks = salt['pillar.get']('mapred_data_disks', ['/data']) %}

{% set username = 'yarn' %}
{% set uid = hadoop_users.get(username, '6003') %}
{{ hadoop_user(username, uid) }}

{% set resourcemanager_host = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() -%}
{% set resourcemanager_port = salt['pillar.get']('mapred:config:resourcemanager_port', '8032') %}

{% for disk in yarn_disks %}
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
{{ disk }}/yarn/logs:
  file.directory:
    - user: yarn
    - group: hadoop
    - require:
      - file: {{ disk }}/yarn
{% endfor %}

{{ hadoop['alt_config'] }}/yarn-site.xml:
  file.managed:
    - source: salt://hadoop/conf/yarn-site.xml
    - template: jinja
    - context:
      yarn_disks: {{ yarn_disks }}
      resourcemanager_host: {{ resourcemanager_host }}

{{ hadoop['alt_config'] }}/capacity-scheduler.xml:
  file.copy:
    - source: {{ hadoop['real_config_dist'] }}/capacity-scheduler.xml
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: {{ hadoop['real_config'] }}
      - alternatives.install: hadoop-conf-link

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}

{{ map.resourcemanager_service_script }}:
  file.managed:
    - source: {{ map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ map.service_script_mode }}
    - template: jinja
    - context:
      hadoop_svc: resourcemanager
      hadoop_home: hadoop_prefix

hadoop-resourcemanager:
  service:
    - running
    - enable: True
{% endif %}

{%- if 'hadoop_slave' in salt['grains.get']('roles', []) %}

{{ map.nodemanager_service_script }}:
  file.managed:
    - source: {{ map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ map.service_script_mode }}
    - template: jinja
    - context:
      hadoop_svc: nodemanager
      hadoop_home: hadoop_prefix

hadoop-nodemanager:
  service:
    - running
    - enable: True
{% endif %}

{%- endif %}