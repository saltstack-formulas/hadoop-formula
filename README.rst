hadoop
======

Formula to set up and configure hadoop components

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/topics/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

Formula Dependencies
--------------------

* hostsfile
* sun-java

``hadoop``
-------

Downloads the hadoop tarball from the hadoop:source_url, installs the package, creates the hadoop group for all other components to share.

``hadoop.hdfs``
--------------

Installs the hdfs service configuration and starts the hdfs services.
Which services hadoop ends up running on a given host will depend on the text list files in the
configuration directory and - in turn - on the roles defined via salt grains:

- hadoop_master will run the hadoop-namenode and hadoop-secondarynamenode services
- hadoop_slave will run the hadoop-datanode service

``hadoop.mapred``
--------------

Installs the mapreduce service scripts and configuration, adds directories.
Which services end up running on a given host will again depend on the role(s) assigned via grains:

- hadoop_master will run the hadoop-jobtracker service
- hadoop_slave will run the hadoop-tasktracker service

``hadoop.snappy``
----------------

Install snappy and snappy-devel system packages, adds a jar and shared lib compiled off of https://code.google.com/p/hadoop-snappy and also puts symlinks to the snappy libs in place, thus providing compression with snappy to the ecosystem.

``hadoop.yarn``
--------------

Installs the yarn daemon scripts and configuration (if a hadoop 2.2+ version was installed), adds directories.
Which services end up running on a given host will again depend on the role(s) assigned via grains:

- hadoop_master will run the hadoop-resourcemanager service
- hadoop_slave will run the hadoop-nodemanager service

Configuration
-------------

As mentioned above, all installation and configuration is assinged via roles. 
For the namenode address to be dynamically configured it is necessary to setup salt mine like below::

    mine_functions:
      network.interfaces: []
      grains.items: []

