include:
  - hadoop.hdfs

{% from "hadoop/map.jinja" import map with context %}

{%- set hadoop = pillar.get('hadoop', {}) %}
{%- set mapred = pillar.get('mapred', {}) %}
{%- set version = hadoop.get('version', '1.2.1') %}
{%- set major   = version.split('.')|first() %}
{% set alt_config   = salt['pillar.get']('hadoop:config:directory', '/etc/hadoop/conf') %}
{% set mapred_disks = salt['pillar.get']('mr_disks', ['/data']) %}
{% set username = 'mapred' %}
{% set uid = salt['pillar.get']('hadoop:users:mapred', '6002') %}
{% set userhome = '/home/' + username %}

{% set jobtracker_host = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() -%}
{% set jobtracker_port = salt['pillar.get']('mapred:config:jobtracker_port', '9001') %}

{%- set hadoop_prefix  = salt['pillar.get']('hadoop:prefix', '/usr/lib/hadoop') %}
{%- if major == '1' %}
{%- set dfs_cmd = hadoop_prefix + '/bin/hadoop dfs' %}
{%- else %}
{%- set dfs_cmd = hadoop_prefix + '/bin/hdfs' %}
{%- endif %}

{{ username }}:
  group.present:
    - gid: {{ uid }}
  user.present:
    - uid: {{ uid }}
    - gid: {{ uid }}
    - home: {{ userhome }}
    - groups: ['hadoop']
    - require:
      - group: hadoop
      - group: {{ username }}
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - names:
      - /var/log/hadoop/{{ username }}
      - /var/run/hadoop/{{ username }}
      - /var/lib/hadoop/{{ username }}
    - require:
      - file.directory: /var/lib/hadoop
      - file.directory: /var/run/hadoop
      - file.directory: /var/log/hadoop

{{ userhome }}/.ssh:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 744
    - require:
      - user: {{ username }}
      - group: {{ username }}

{{ username }}_private_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_dsa
    - user: {{ username }}
    - group: {{ username }}
    - mode: 600
    - source: salt://hadoop/files/dsa-{{ username }}
    - require:
      - file.directory: {{ userhome }}/.ssh

{{ username }}_public_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_dsa.pub
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - source: salt://hadoop/files/dsa-{{ username }}.pub
    - require:
      - file.managed: {{ username }}_private_key

ssh_dss_{{ username }}:
  ssh_auth.present:
    - user: {{ username }}
    - source: salt://hadoop/files/dsa-{{ username }}.pub
    - require:
      - file.managed: {{ username }}_private_key

{{ userhome }}/.ssh/config:
  file.managed:
    - source: salt://hadoop/conf/ssh/ssh_config
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - require:
      - file.directory: {{ userhome }}/.ssh

{{ userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:/usr/lib/hadoop/bin:/usr/lib/hadoop/sbin

{% for disk in mapred_disks %}
{{ disk }}/mapred:
  file.directory:
    - user: mapred
    - group: root
    - makedirs: True
{% endfor %}

{{ alt_config }}/mapred-site.xml:
  file.managed:
    - source: salt://hadoop/conf/mapred-site.xml
    - template: jinja
    - context:
      mapred_disks: {{ mapred_disks }}
      mapred: {{ mapred }}
      jobtracker_host: {{ jobtracker_host }}
      jobtracker_port: {{ jobtracker_port }}
      major: {{ major }}

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}

make-tempdir:
  cmd.run:
    - user: hdfs
    - name: {{ dfs_cmd }} -mkdir /tmp
    - unless: {{ dfs_cmd }} -stat /tmp
    - require:
      - service: hdfs-services

set-tempdir:
  cmd.wait:
    - user: hdfs
    - watch:
      - cmd: make-tempdir
    - names:
      - {{ dfs_cmd }} -chmod 777 /tmp
      # - {{ dfs_cmd }} -chmod +t /tmp


{{ map.jobtracker_service_script }}:
  file.managed:
    - source: {{ map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ map.service_script_mode }}
    - template: jinja
    - context:
      hadoop_svc: jobtracker
      hadoop_home: hadoop_prefix

hadoop-jobtracker:
  service:
    - running
    - enable: True
{% endif %}

{%- if 'hadoop_slave' in salt['grains.get']('roles', []) %}

{{ map.tasktracker_service_script }}:
  file.managed:
    - source: {{ map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ map.service_script_mode }}
    - template: jinja
    - context:
      hadoop_svc: tasktracker
      hadoop_home: hadoop_prefix

hadoop-tasktracker:
  service:
    - running
    - enable: True
{% endif %}

