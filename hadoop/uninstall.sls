{%- from 'hadoop/settings.sls' import hadoop with context %}

hadoop-files-removed:
  file.absent:
    - names:
      - {{ hadoop.log_root }}
      - /var/run/hadoop
      - /var/lib/hadoop
      - /var/log/hadoop
      - {{ hadoop['real_home'] }}
      - {{ hadoop['alt_home'] }}
      - /usr/bin/hadoop
      - /usr/bin/hdfs
      - /usr/bin/mapred
      - /usr/bin/yarn
      - /etc/profile.d/hadoop.sh
      - /etc/hadoop
      - {{ hadoop['real_config'] }}
      - {{ hadoop['alt_config'] }}
      - /etc/default/hadoop

include:
  - hadoop.mapred.uninstall
  - hadoop.yarn.uninstall
  - hadoop.hdfs.uninstall
