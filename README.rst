======
hadoop
======

Formula to set up and configure hadoop components

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``hadoop``
----------

Downloads the hadoop tarball from the hadoop:source_url, installs the package, creates the hadoop group for all other components to share.

``hadoop.hdfs``
---------------

Installs the hdfs service configuration and starts the hdfs services.
Which services hadoop ends up running on a given host depends on the roles defined via salt grains:

- hadoop_master will run the hadoop-namenode and hadoop-secondarynamenode services
- hadoop_slave will run the hadoop-datanode service

::

    roles:
      - hadoop_slave

``hadoop.mapred``
-----------------

Installs the mapreduce service scripts and configuration, adds directories.
Which services end up running on a given host will again depend on the role(s) assigned via grains:

- hadoop_master will run the hadoop-jobtracker service
- hadoop_slave will run the hadoop-tasktracker service

``hadoop.snappy``
-----------------

Install snappy and snappy-devel system packages, adds a jar and shared lib compiled off of https://code.google.com/p/hadoop-snappy and also puts symlinks to the snappy libs in place, thus providing compression with snappy to the ecosystem.

``hadoop.yarn``
---------------

Installs the yarn daemon scripts and configuration (if a hadoop 2.2+ version was installed), adds directories.
Which services end up running on a given host will again depend on the role(s) assigned via grains:

- hadoop_master will run the hadoop-resourcemanager service
- hadoop_slave will run the hadoop-nodemanager service

Formula Dependencies
====================

* ``hostsfile``
* ``sun-java``

Salt Minion Configuration
=========================

As mentioned above, all installation and configuration is assinged via roles. 
Mounted disks (or just directories) can be configured for use with hdfs and mapreduce via grains.

Example ``/etc/salt/grains`` for a datanode:
::

    hdfs_data_disks:
      - /data1
      - /data2
      - /data3
      - /data4

    mapred_data_disks:
      - /data1
      - /data2
      - /data3
      - /data4

    yarn_data_disks:
      - /data1
      - /data2
      - /data3
      - /data4

    roles:
      - hadoop_slave

For the namenode address to be dynamically configured it is necessary to setup salt mine like below /etc/salt/minion.d/mine_functions.conf:

::

    mine_functions:
      network.interfaces: []
      network.ip_addrs: []
      grains.items: []

One thing to keep in mind here is that the implementation currently relies on the minion_id of all nodes to match their FQDN (which is the default) and working name resolution. 

Hadoop configuration
====================

The hadoop formula exposes the general (cluster-independent) part of the main configuration files (core-site.xml, hdfs-site.sml, mapred-site.xml) 
as pillar keys.

Example:
::

    hadoop:
      config:
        tmp_dir: /var/lib/hadoop/tmp
        directory: /etc/hadoop/conf
        core-site:
          io.native.lib.available:
            value: true
          io.file.buffer.size:
            value: 65536
          fs.trash.interval:
            value: 60

Where the core-site part will appear in core-site.xml as:
::

    <property>
        <name>io.native.lib.available</name>
        <value>True</value>
    </property>

    <property>
        <name>fs.trash.interval</name>
        <value>60</value>
    </property>

    <property>
        <name>io.file.buffer.size</name>
        <value>65536</value>
    </property>

Please note that host- and cluster-specific values are not exposed - the formula controls these (think: fs.default.name)

