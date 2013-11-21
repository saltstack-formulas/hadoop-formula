include:
  - hadoop

/tmp/hadoop-snappy-0.0.1.tgz:
  file.managed:
    - source: salt://hadoop/libs/hadoop-snappy-0.0.1.tgz

# TODO: ubuntu names
snappy-libs:
  pkg.installed:
    - names:
      - snappy
      - snappy-devel

install-hadoop-snappy:
  cmd.run:
    - name: tar xzf /tmp/hadoop-snappy-0.0.1.tgz
    - cwd: /usr/lib/hadoop
    - unless: test -f /usr/lib/hadoop/lib/hadoop-snappy-0.0.1.jar
    - require:
      - file.managed: /tmp/hadoop-snappy-0.0.1.tgz
      - alternatives.install: hadoop-home-link
      - pkg.installed: snappy-libs

{%- set snappies = salt['cmd.run_stdout']('cd /usr/lib64 && ls -1 libsnappy*') %}
{%- for lib in snappies.split() %}
/usr/lib/hadoop/lib/native/Linux-amd64-64/{{ lib }}:
  file.symlink:
    - target: /usr/lib64/{{ lib }}
{%- endfor %}
