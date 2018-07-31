{%- from 'hadoop/settings.sls' import hadoop with context %}

hadoop:
  group.present:
    - gid: {{ hadoop.users['hadoop'] }}

{%- if grains['os_family'] == 'RedHat' %}
redhat-lsb:
  pkg.installed
{%- endif %}

create-common-folders:
  file.directory:
    - user: root
    - group: hadoop
    - mode: 775
    - names:
      - {{ hadoop.log_root }}
      - /var/run/hadoop
      - /var/lib/hadoop
    - require:
      - group: hadoop
    - makedirs: True

{%- if hadoop.log_root != hadoop.default_log_root %}
/var/log/hadoop:
  file.symlink:
    - target: {{ hadoop.log_root }}
{%- endif %}

vm.swappiness:
  sysctl:
    - present
    - value: 0

vm.overcommit_memory:
  sysctl:
    - present
    - value: 0

unpack-hadoop-dist:
  archive.extracted:
    - name: /usr/lib/
    - source: {{ hadoop.source_url }}
{%- if hadoop.source_hash %}
    - source_hash: {{ hadoop.source_hash }}
{%- else %}
    - skip_verify: True
{%- endif %}
    - archive_format: tar
    - if_missing: {{ hadoop['real_home'] }}
    - require_in:
      - file: hadoop-home-link
      - file: hadoop-bin-link
      - file: hdfs-bin-link
      - file: mapred-bin-link
      - file: yarn-bin-link

hadoop-home-link:
  file.symlink:
    - name: {{ hadoop['alt_home'] }}
    - target: {{ hadoop['real_home'] }}

hadoop-bin-link:
  file.symlink:
    - name: /usr/bin/hadoop
    - target: {{ hadoop['alt_home'] }}/bin/hadoop
      
hdfs-bin-link:
  file.symlink:
    - name: /usr/bin/hdfs
    - target: {{ hadoop['alt_home'] }}/bin/hdfs
      
mapred-bin-link:
  file.symlink:
    - name: /usr/bin/mapred
    - target: {{ hadoop['alt_home'] }}/bin/mapred
      
yarn-bin-link:
  file.symlink:
    - name: /usr/bin/yarn
    - target: {{ hadoop['alt_home'] }}/bin/yarn
      
{%- if hadoop.cdhmr1 %}

{{ hadoop.alt_home }}/share/hadoop/mapreduce:
  file.symlink:
    - target: {{ hadoop.alt_home }}/share/hadoop/mapreduce1
    - force: True

rename-bin:
  cmd.run:
    - name: mv {{ hadoop.alt_home }}/bin {{ hadoop.alt_home }}/bin-mapreduce2
    - unless: test -L {{ hadoop.alt_home }}/bin

rename-config:
  cmd.run:
    - name: mv {{ hadoop.alt_home }}/etc/hadoop {{ hadoop.alt_home }}/etc/hadoop-mapreduce2
    - unless: test -L {{ hadoop.alt_home }}/etc/hadoop

{{ hadoop.alt_home }}/bin:
  file.symlink:
    - target: {{ hadoop.alt_home }}/bin-mapreduce1
    - force: True

{{ hadoop.alt_home }}/etc/hadoop:
  file.symlink:
    - target: {{ hadoop.alt_home }}/etc/hadoop-mapreduce1
    - force: True

{% endif %}

/etc/profile.d/hadoop.sh:
  file.managed:
    - source: salt://hadoop/files/hadoop.sh.jinja
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      hadoop_config: {{ hadoop['alt_config'] }}
      alt_home: {{ hadoop.get('alt_home', '/usr/lib/hadoop') }}

hadoop-setup-env-vars:
  cmd.run:
    - name: source /etc/profile.d/hadoop.sh
    - onchanges:
      - file: /etc/profile.d/hadoop.sh
      
{% if (hadoop['major_version'] == '1') and not hadoop.cdhmr1 %}
{% set real_config_src = hadoop['real_home'] + '/conf' %}
{% else %}
{% set real_config_src = hadoop['real_home'] + '/etc/hadoop' %}
{% endif %}

/etc/hadoop:
  file.directory:
    - user: root
    - group: root
    - mode: 755

move-hadoop-dist-conf:
  file.directory:
    - name: {{ hadoop['real_config'] }}
    - user: root
    - group: root
  cmd.run:
    - name: mv  {{ real_config_src }} {{ hadoop.real_config_dist }}
    - unless: test -d {{ hadoop.real_config_dist }}
    - onlyif: test -d {{ real_config_src }}
    - require:
      - file: /etc/hadoop

{{ real_config_src }}:
  file.symlink:
    - target: {{ hadoop['alt_config'] }}
    - force: true
    - require:
      - cmd: move-hadoop-dist-conf

hadoop-conf-link:
  file.symlink:
    - name: {{ hadoop['alt_config'] }}
    - target: {{ hadoop['real_config'] }}
    - require:
      - file: {{ hadoop['real_config'] }}
      
{{ hadoop['real_config'] }}/log4j.properties:
  file.copy:
    - source: {{ hadoop['real_config_dist'] }}/log4j.properties
    - user: root
    - group: root
    - mode: 644
    - require:
      - file: {{ hadoop['real_config'] }}
      - file: hadoop-conf-link

{{ hadoop['real_config'] }}/hadoop-env.sh:
  file.managed:
    - source: salt://hadoop/conf/hadoop-env.sh
    - template: jinja
    - mode: 644
    - user: root
    - group: root
    - context:
      java_home: {{ hadoop.java_home }}
      hadoop_home: {{ hadoop.alt_home }}
      hadoop_config: {{ hadoop.alt_config }}

{%- if grains.os == 'Ubuntu' %}
/etc/default/hadoop:
  file.managed:
    - source: salt://hadoop/files/hadoop.jinja
    - mode: '644'
    - template: jinja
    - user: root
    - group: root
    - context:
      java_home: {{ hadoop.java_home }}
      hadoop_home: {{ hadoop.alt_home }}
      hadoop_config: {{ hadoop.alt_config }}
{%- endif %}
