{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/yarn/settings.sls' import yarn with context %}

hadoop-yarn-stopped:
  service.dead:
    - names: 
      - hadoop-historyserver
      - hadoop-resourcemanager
      - hadoop-nodemanager
    - enable: False

hadoop-yarn-services-removed:
  file.absent:
    - names:
      - /etc/systemd/system/hadoop-historyserver.service
      - /etc/init.d/hadoop-historyserver
      - /etc/systemd/system/hadoop-resourcemanager.service
      - /etc/init.d/hadoop-resourcemanager
      - /etc/systemd/system/hadoop-nodemanager.service
      - /etc/init.d/hadoop-nodemanager
    - require:
      - service: hadoop-yarn-stopped
{%- if grains.get('systemd') %}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: hadoop-yarn-services-removed
{%- endif %}

hadoop-yarn-files-removed:
  file.absent:
    - names:
      - {{ hadoop.alt_config }}/container-executor.cfg
      - {{ hadoop.alt_config }}/yarn-site.xml
      - {{ hadoop.alt_config }}/capacity-scheduler.xml

hadoop-yarn-data-removed:
  file.absent:
    - names:
{% for disk in yarn.local_disks %}
      - {{ disk }}/yarn
{% endfor %}
