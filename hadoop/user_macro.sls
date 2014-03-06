{% macro hadoop_user(username, uid) -%}
{%- set userhome='/home/'+username %}
{{ username }}:
  group.present:
    - gid: {{ uid }}
  user.present:
    - uid: {{ uid }}
    - gid: {{ uid }}
    - home: {{ userhome }}
    - groups: ['hadoop']
    - require:
      - group: {{ username }}
#  file.directory:
#    - user: {{ username }}
#    - group: hadoop
#    - names:
#      - /var/log/hadoop/{{ username }}
#      - /var/run/hadoop/{{ username }}
#      - /var/lib/hadoop/{{ username }}

{{ userhome }}/.ssh:
  file.directory:
    - user: {{ username }}
    - group: {{ username }}
    - mode: 744
    - require:
      - user: {{ username }}
      - group: {{ username }}

{{ username }}_private_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_dsa
    - user: {{ username }}
    - group: {{ username }}
    - mode: 600
    - source: salt://hadoop/files/dsa-{{ username }}
    - require:
      - file: {{ userhome }}/.ssh

{{ username }}_public_key:
  file.managed:
    - name: {{ userhome }}/.ssh/id_dsa.pub
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - source: salt://hadoop/files/dsa-{{ username }}.pub
    - require:
      - file: {{ username }}_private_key

ssh_dss_{{ username }}:
  ssh_auth.present:
    - user: {{ username }}
    - source: salt://hadoop/files/dsa-{{ username }}.pub
    - require:
      - file: {{ username }}_private_key

{{ userhome }}/.ssh/config:
  file.managed:
    - source: salt://hadoop/conf/ssh/ssh_config
    - user: {{ username }}
    - group: {{ username }}
    - mode: 644
    - require:
      - file: {{ userhome }}/.ssh

{{ userhome }}/.bashrc:
  file.append:
    - text:
      - export PATH=$PATH:/usr/lib/hadoop/bin:/usr/lib/hadoop/sbin

/etc/security/limits.d/99-{{username}}.conf:
  file.managed:
    - mode: 644
    - user: root
    - contents: |
        {{username}} soft nofile 65536
        {{username}} hard nofile 65536
        {{username}} soft nproc 8092
        {{username}} hard nproc 8092

{%- endmacro %}