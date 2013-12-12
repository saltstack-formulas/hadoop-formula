# this would mean we now have /etc/jmxtrans/json
{%- set all_roles    = salt['grains.get']('roles', []) %}
{%- if 'monitor' in all_roles %}

include:
  - jmxtrans

{%- set jsondir = '/etc/jmxtrans/json' %}

# TODO: add yarn support
{%- if 'hadoop_slave' in all_roles %}
{{jsondir}}/datanode.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/datanode.json
    - template: jinja

{{jsondir}}/tasktracker.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/tasktracker.json
    - template: jinja
{%- endif %}

{%- if 'hadoop_master' in all_roles %}
{{jsondir}}/namenode.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/namenode.json
    - template: jinja

{{jsondir}}/jobtracker.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/jobtracker.json
    - template: jinja
{%- endif %}

{%- if 'hadoop_master' in all_roles or 'hadoop_slave' in all_roles %}
restart-jmxtrans-for-hadoop:
  module.wait:
    - name: service.restart
    - m_name: jmxtrans
    - watch:
{%- if 'hadoop_master' in all_roles %}
      - file: {{jsondir}}/namenode.json
      - file: {{jsondir}}/jobtracker.json
{%- endif %}
{%- if 'hadoop_slave' in all_roles %}
      - file: {{jsondir}}/datanode.json
      - file: {{jsondir}}/tasktracker.json
{%- endif %}

{%- endif %}

{%- endif %}
