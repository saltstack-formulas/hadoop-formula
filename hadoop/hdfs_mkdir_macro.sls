{% macro hdfs_mkdir(name, user, group, mode, cmd) -%}
{%- set localname = name | replace('/', '-') %}
make{{ localname }}-dir:
  cmd.run:
    - user: hdfs
    - name: {{ cmd }} -mkdir {{ name }}
    - unless: {{ cmd }} -stat {{ name }}

chown{{ localname }}-dir:
  cmd.run:
    - user: hdfs
{%- if group %}
    - name: {{ cmd }} -chown {{ user }}:{{ group }} {{ name }}
{%- else %}
    - name: {{ cmd }} -chown {{ user }} {{ name }}
{%- endif %}

chmod{{ localname }}-dir:
  cmd.run:
    - user: hdfs
    - name: {{ cmd }} -chmod {{ mode }} {{ name }}
{%- endmacro %}
