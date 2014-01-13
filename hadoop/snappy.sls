include:
  - hadoop

{%- from 'hadoop/settings.sls' import hadoop with context %}

{%- if grains['os_family'] in ['Debian', 'RedHat'] %}
snappy-libs:
  pkg.installed:
    - order: 1
    - names:
{%- if grains['os_family'] == 'RedHat' %}
      - snappy
      - snappy-devel
{%- else %}
      - libsnappy1
      - libsnappy-dev
{%- endif %}
{%- endif %}

# TODO: this is a bug - won't work at first execution because the libs are not yet installed
{%- set snappies = salt['cmd.run_stdout']('cd /usr/lib64 && ls -1 libsnappy*') %}

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
      - file.managed: /tmp/hadoop-snappy-0.0.1.tgz
      - alternatives.install: hadoop-home-link
      - pkg.installed: snappy-libs

{%- for lib in snappies.split() %}
/usr/lib/hadoop/lib/native/Linux-amd64-64/{{ lib }}:
  file.symlink:
    - target: /usr/lib64/{{ lib }}
{%- endfor %}

{% endif %}