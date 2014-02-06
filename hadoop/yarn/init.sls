include:
  - hadoop.mapred

{%- from "hadoop/settings.sls" import hadoop with context %}
{%- from "hadoop/yarn/settings.sls" import yarn with context %}
{%- from "hadoop/user_macro.sls" import hadoop_user with context %}
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
{{ disk }}/yarn/logs:
  file.directory:
    - user: yarn
    - group: hadoop
    - require:
      - file: {{ disk }}/yarn
{% endfor %}

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
    - require:
      - file: {{ hadoop['real_config'] }}
      - alternatives.install: hadoop-conf-link

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}

/etc/init.d/hadoop-resourcemanager:
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