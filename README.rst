===
hadoop
===

Formula to set up and configure hadoop components

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/topics/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``hadoop``
-------

Downloads the hadoop tarball from the master (must exist as hadoop-<version>.tar.gz), installs the package. Creates the hadoop group for all other components to share.

``hadoop.hdfs``
--------------

Installs the server configuration and starts the hadoop master server.
Which services hadoop ends up running on a given host will depend on the text list files in the
configuration directory and - in turn - on the roles defined via salt grains:

- hadoop_master will run the namenode and secondarynamenode processes
- hadoop_slave will run a datanode process

``hadoop.mapred``
--------------

Installs the mapreduce daemon scripts and configuration, adds directories.
Which services end up running on a given host will again depend on the role(s) assigned via grains:

- hadoop_master will run the jobtracker process
- hadoop_slave will run a tasktracker process

``hadoop.yarn``
--------------

To be implemented