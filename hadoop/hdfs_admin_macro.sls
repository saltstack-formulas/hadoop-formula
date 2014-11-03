{% macro hdfs_admin(cmd, arg1, hdfs_cmd) -%}
{%- set localname = arg1 | replace('/', '-') %}

exec-dfsadmin-{{ localname }}:
  cmd.run:
    - user: hdfs
    - name: {{ hdfs_cmd }} {{ cmd }} {{ arg1 }}
{%- endmacro %}
