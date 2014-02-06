include:
  - hadoop

{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hdfs/settings.sls' import hdfs with context %}

{%- set pillar_defaults = salt['pillar.get']('hadoop', {})
# now build the dict
{%- set config = pillar_defaults %}
