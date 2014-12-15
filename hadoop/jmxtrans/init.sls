# this would mean we now have /etc/jmxtrans/json
{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}

{# this is new for me and was not shown in README either can this be removed or 
  do you think that adding another targeting rule would be better?, i never saw/used this role before #}
{%- if 'monitor' in all_roles %}

include:
  - jmxtrans

{%- set jsondir = '/etc/jmxtrans/json' %}

# TODO: add yarn support
{% if hdfs.is_datanode %}
{{jsondir}}/datanode.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/datanode.json
    - template: jinja

{{jsondir}}/tasktracker.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/tasktracker.json
    - template: jinja
{%- endif %}

{% if hdfs.is_namenode %}
{{jsondir}}/namenode.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/namenode.json
    - template: jinja

{{jsondir}}/jobtracker.json:
  file.managed:
    - source: salt://hadoop/jmxtrans/jobtracker.json
    - template: jinja
{%- endif %}

{% if hdfs.is_namenode or hdfs.is_datanode %}
restart-jmxtrans-for-hadoop:
  module.wait:
    - name: service.restart
    - m_name: jmxtrans
    - watch:
{% if hdfs.is_namenode %}
      - file: {{jsondir}}/namenode.json
      - file: {{jsondir}}/jobtracker.json
{%- endif %}
{% if hdfs.is_datanode %}
      - file: {{jsondir}}/datanode.json
      - file: {{jsondir}}/tasktracker.json
{%- endif %}

{%- endif %}

{%- endif %}
