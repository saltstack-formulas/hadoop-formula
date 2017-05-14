{%- from 'hadoop/settings.sls' import hadoop with context %}
{%- from 'hadoop/mapred/settings.sls' import mapred with context %}

hadoop-mapred-stopped:
  service.dead:
    - names: 
      - hadoop-jobtracker
      - hadoop-tasktracker
    - enable: False

hadoop-mapred-services-removed:
  file.absent:
    - names:
      - /etc/systemd/system/hadoop-jobtracker.service
      - /etc/init.d/hadoop-jobtracker
      - /etc/systemd/system/hadoop-tasktracker.service
      - /etc/init.d/hadoop-tasktracker
    - require:
      - service: hadoop-mapred-stopped
{%- if grains.get('systemd') %}
  module.run:
    - name: service.systemctl_reload
    - onchanges:
      - file: hadoop-mapred-services-removed
{%- endif %}

hadoop-mapred-files-removed:
  file.absent:
    - names:
      - {{ hadoop['alt_config'] }}/mapred-site.xml
      - {{ hadoop['alt_config'] }}/taskcontroller.cfg

hadoop-mapred-data-removed:
  file.absent:
    - names:
{% for disk in mapred.local_disks %}
      - {{ disk }}/mapred
{% endfor %}
