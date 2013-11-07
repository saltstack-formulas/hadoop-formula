{%- set hadoop = pillar.get('hadoop', {}) %}
{%- set hadoop_users = hadoop.get('users', {}) %}

hadoop:
  group.present:
    - gid: {{ hadoop_users.get('hadoop', '6000') }}
  file.directory:
    - user: root
    - group: hadoop
    - mode: 775
    - names:
      - /var/log/hadoop
      - /var/run/hadoop
      - /var/lib/hadoop
    - require:
      - group: hadoop

{% set version = hadoop.get('version', '1.2.1') %}
{% set major   = version.split('.')|first() %}
{% set version_name = 'hadoop-' + version %}
{% set hadoop_tgz = version_name + '.tar.gz' %}
{% set hadoop_tgz_path  = '/tmp/' + hadoop_tgz %}

{% set hadoop_alt_home  = salt['pillar.get']('hadoop:prefix', '/usr/lib/hadoop') %}
{% set real_home = '/usr/lib/' + version_name %}
{% set alt_config   = salt['pillar.get']('hadoop:config:directory', '/etc/hadoop/conf') %}
{% set real_config = alt_config + '-' + version %}
{% set real_config_dist = alt_config + '.dist' %}

vm.swappiness:
  sysctl:
    - present
    - value: 10

vm.overcommit_memory:
  sysctl:
    - present
    - value: 0

{{ hadoop_tgz_path }}:
  file.managed:
{%- if hadoop['source'] is defined %}
    - source: {{ hadoop.get('source') }}
    - source_hash: {{ hadoop.get('source_hash', '') }}
{%- else %}
    - source: salt://hadoop/files/{{ hadoop_tgz }}
{% endif %}

unpack-hadoop-dist:
  cmd.run:
    - name: tar xzf {{ hadoop_tgz_path }}
    - cwd: /usr/lib
    - unless: test -d {{ real_home }}/lib
    - require:
      - file.managed: {{ hadoop_tgz_path }}
  alternatives.install:
    - name: hadoop-home-link
    - link: {{ hadoop_alt_home }}
    - path: {{ real_home }}
    - priority: 30
    - require:
      - cmd.run: unpack-hadoop-dist
  file.directory:
    - name: {{ real_home }}
    - user: root
    - group: root
    - recurse:
      - user
      - group
    - require:
      - cmd.run: unpack-hadoop-dist

/etc/profile.d/hadoop.sh:
  file.managed:
    - source: salt://hadoop/files/hadoop.sh.jinja
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      hadoop_config: {{ alt_config }}

{% if (major == '1') %}
{% set real_config_src = real_home + '/conf' %}
{% else %}
{% set real_config_src = real_home + '/etc/hadoop' %}
{% endif %}

/etc/hadoop:
  file.directory:
    - owner: root
    - group: root
    - mode: 755

move-hadoop-dist-conf:
  file.directory:
    - name: {{ real_config }}
    - user: root
    - group: root
  cmd.run:
    - name: mv  {{ real_config_src }} {{ real_config_dist }}
    - unless: test -L {{ real_config_src }}
    - onlyif: test -d {{ real_config_src }}
    - require:
      - file.directory: {{ real_home }}
      - file.directory: /etc/hadoop

{{ real_config_src }}:
  file.symlink:
    - target: {{ alt_config }}
    - require:
      - cmd: move-hadoop-dist-conf

hadoop-conf-link:
  alternatives.install:
    - link: {{ alt_config }}
    - path: {{ real_config }}
    - priority: 30
    - require:
      - file.directory: {{ real_config }}

{{ real_config }}/log4j.properties:
  file.copy:
    - source: {{ real_config_dist }}/log4j.properties
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: {{ real_config }}
      - alternatives.install: hadoop-conf-link

{{ real_config }}/hadoop-env.sh:
  file.managed:
    - source: salt://hadoop/conf/hadoop-env.sh
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      java_home: {{ salt['pillar.get']('java_home', '/usr/lib/java') }}
      hadoop_home: {{ hadoop_alt_home }}
      hadoop_config: {{ alt_config }}
