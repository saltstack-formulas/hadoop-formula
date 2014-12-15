{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}

{% if salt['match.' ~ hadoop.targeting_method](hdfs.namenode_target) %}

{%- for filename in hdfs.load.keys() %}
{%- set url = hdfs.load.get(filename, '') %}
{%- set tmppath = '/tmp/' + filename %}

{%- if url != '' %}
download-{{ filename }}:
  cmd.run:
    - name: curl -L '{{ url }}' -o {{ tmppath }}
    - cwd: /tmp
    - unless: test -f {{ tmppath }}

hdfsload-{{ filename }}:
  cmd.run:
    - name: {{ hadoop.dfs_cmd }} -copyFromLocal {{ tmppath }} {{ tmppath }}
    - user: hdfs
    - cwd: /tmp
    - unless: {{ hadoop.dfs_cmd }} -stat {{ tmppath }}
    - onlyif: test -f {{ tmppath }}

{%- endif %}
{%- endfor %}
{%- endif %}
