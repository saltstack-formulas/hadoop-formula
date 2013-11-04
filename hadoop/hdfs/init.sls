include:
  - hadoop

{% from "hadoop/map.jinja" import map with context %}

{%- set hadoop = pillar.get('hadoop', {}) %}
{%- set version = hadoop.get('version', '1.2.1') %}
{%- set major   = version.split('.')|first() %}
{% set alt_config   = salt['pillar.get']('hadoop:config:directory', '/etc/hadoop/conf') %}
{% set hdfs_disks = salt['grains.get']('hdfs_data_disks', ['/data']) %}
{% set username = 'hdfs' %}
{% set uid = salt['pillar.get']('hadoop:users:hdfs', '6001') %}
{% set userhome = '/home/' + username %}

{% set namenode_host = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() -%}

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
    - source: salt://misc/ssh_config
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - require:
      - file.directory: {{ userhome }}/.ssh

{{ userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:/usr/lib/hadoop/bin:/usr/lib/hadoop/sbin

{% for disk in hdfs_disks %}
{{ disk }}/hdfs:
  file.directory:
    - user: root
    - group: root
    - makedirs: True
{% if 'hadoop_master' in salt['grains.get']('roles', []) %}
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

{% if 'hadoop_slave' in salt['grains.get']('roles', []) %}

{{ disk }}/hdfs/dn:
  file.directory:
    - user: {{ username }}
    - group: hadoop
    - makedirs: True
{% endif %}

{% endfor %}

{{ alt_config }}/core-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/core-site.xml
    - template: jinja
    - context:
      hdfs_disks: {{ hdfs_disks }}
      hadoop: {{ hadoop }}
      namenode_host: {{ namenode_host }}

{{ alt_config }}/hdfs-site.xml:
  file.managed:
    - source: salt://hadoop/conf/hdfs/hdfs-site.xml
    - template: jinja
    - context:
      hdfs_disks: {{ hdfs_disks }}
      hadoop: {{ hadoop }}
      namenode_host: {{ namenode_host }}
      major: {{ major }}

{{ alt_config }}/masters:
  file.managed:
    - source: salt://hadoop/conf/hdfs/masters
    - template: jinja
    - context:
      namenode_host: {{ namenode_host }}

{{ alt_config }}/slaves:
  file.managed:
    - source: salt://hadoop/conf/hdfs/slaves
    - template: jinja

{%- if 'hadoop_master' in salt['grains.get']('roles', []) %}
{%- set test_folder = hdfs_disks|first() + '/hdfs/nn/current' %}

format-namenode:
  cmd.run:
{%- if major == '1' %}
    - name: /usr/lib/hadoop/bin/hadoop namenode -format -force
{%- else %}
    - name: /usr/lib/hadoop/bin/hdfs namenode -format
{% endif %}
    - user: hdfs
    - unless: test -d {{ test_folder }}

{{ map.namenode_service_script }}:
  file.managed:
    - source: {{ map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ map.service_script_mode }}
    - template: jinja

{{ map.secondarynamenode_service_script }}:
  file.managed:
    - source: {{ map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ map.service_script_mode }}
    - template: jinja

hadoop-namenode:
  service:
    - running
    - enable: True

hadoop-secondarynamenode:
  service:
    - running
    - enable: True

{%- elif 'hadoop_slave' in salt['grains.get']('roles', []) %}

{{ map.datanode_service_script }}:
  file.managed:
    - source: {{ map.service_script_source }}
    - user: root
    - group: root
    - mode: {{ map.service_script_mode }}
    - template: jinja

hadoop-datanode:
  service:
    - running
    - enable: True

{% endif %}

