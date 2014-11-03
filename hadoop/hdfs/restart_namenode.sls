restart-hdfs-nameode:
  cmd.run:
    - user: root
    - name: service hadoop-namenode restart
    - onlyif: test -f /etc/init.d/hadoop-namenode

