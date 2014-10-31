{%- from 'hadoop/settings.sls' import hadoop with context %}

{%- if grains['os_family'] in ['Debian', 'RedHat', 'Suse'] %}
snappy-libs:
  pkg.installed:
    - order: 1
    - names:
{%- if grains['os_family'] == 'RedHat' %}
      - snappy
      - snappy-devel
{%- elif grains['os_family'] == 'Suse' %}
      - libsnappy1
      - snappy-devel
{%- else %}
      - libsnappy1
      - libsnappy-dev
{%- endif %}
{%- endif %}

{%- if hadoop['major_version'] == '1' %}
/tmp/hadoop-snappy-0.0.1.tgz:
  file.managed:
    - source: salt://hadoop/libs/hadoop-snappy-0.0.1.tgz

install-hadoop-snappy:
  cmd.run:
    - name: tar xzf /tmp/hadoop-snappy-0.0.1.tgz
    - cwd: /usr/lib/hadoop
    - unless: test -f /usr/lib/hadoop/lib/hadoop-snappy-0.0.1.jar
    - require:
      - file: /tmp/hadoop-snappy-0.0.1.tgz
      - alternatives: hadoop-home-link
      - pkg: snappy-libs
{% endif %}

/etc/ld.so.conf.d/hadoop-x86-64.conf:
  file.managed:
    - user: root
    - contents: {{ hadoop.alt_home }}/lib/native

/etc/ld.so.conf.d/java-x86-64.conf:
  file.managed:
    - user: root
    - contents: {{ hadoop.java_home }}/jre/lib/amd64/server

/sbin/ldconfig:
  cmd.run:
    - user: root
    - onlyif: test -d {{ hadoop.alt_home }}/lib/native
