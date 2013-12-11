# this would mean we now have /etc/jmxtrans/json

include:
  - jmxtrans

{%- set jsondir = '/etc/jmxtrans/json' %}
{%- set all_roles    = salt['grains.get']('roles', []) %}

# TODO: add yarn support
{%- if 'hadoop_slave' in all_roles %}
{{jsondir}}/datanode.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/datanode.json

{{jsondir}}/tasktracker.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/tasktracker.json
{%- endif %}

{%- if 'hadoop_master' in all_roles %}
{{jsondir}}/namenode.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/namenode.json

{{jsondir}}/jobtracker.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/jobtracker.json
{%- endif %}

#{%- if 'hadoop_master' in all_roles or 'hadoop_slave' in all_roles %}

#reload-jmxtrans:
#  cmd.wait:
#    - name: service jmxtrans restart
#    - watch:
#{%- if 'hadoop_slave' in all_roles %}
#      - file: {{jsondir}}/datanode.json
#      - file: {{jsondir}}/tasktracker.json
#{%- endif %}
#{%- if 'hadoop_master' in all_roles %}
#      - file: {{jsondir}}/namenode.json
#      - file: {{jsondir}}/jobtracker.json
#{%- endif %}

#{%- endif %}
