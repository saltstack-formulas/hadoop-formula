hadoop formula
==============

0.0.2 (2013-11-05)

- added support for mapreduce (jobtracker and tasktracker daemons)
 
0.0.1 (2013-11-04)

- Initial alpha release
- hadoop sets up the common software, the common hadoop group and the config directory in /etc
- haddop.hdfs sets up directory structures, service scripts, the hdfs user, then formats hdfs namenode
  and starts daemons according to the role(s) of a minion
