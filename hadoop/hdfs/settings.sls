{% set p  = salt['pillar.get']('hdfs', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('hdfs', {}) %}
{% set gc = g.get('config', {}) %}

# TODO: https://github.com/accumulo/hadoop-formula/issues/1 'Replace direct mine.get calls'
{%- set namenode_host  = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() %}
{%- set datanode_hosts = salt['mine.get']('roles:hadoop_slave', 'network.interfaces', 'grain').keys() %}
{%- set datanode_count = salt['mine.get']('roles:hadoop_slave', 'network.ip_addrs', 'grain').keys()|count() %}
{%- set namenode_port  = gc.get('namenode_port', pc.get('namenode_port', '8020')) %}
{%- set namenode_http_port  = gc.get('namenode_http_port', pc.get('namenode_http_port', '50070')) %}
{%- set secondarynamenode_http_port  = gc.get('secondarynamenode_http_port', pc.get('secondarynamenode_http_port', '50090')) %}
{%- set local_disks      = salt['grains.get']('hdfs_data_disks', ['/data']) %}
{%- set repl_override    = gc.get('replication', pc.get('replication', 'x')) %}
{%- set load  = salt['grains.get']('hdfs_load', salt['pillar.get']('hdfs_load', {})) %}

# Todo: this might be a candidate for pillars/grains
# {%- set tmp_root        = local_disks|first() %}
{%- set tmp_dir         = '/tmp' %}

{%- if repl_override == 'x' %}
{%- if datanode_count >= 3 %}
{%- set replicas = '3' %}
{%- elif datanode_count == 2 %}
{%- set replicas = '2' %}
{%- else %}
{%- set replicas = '1' %}
{%- endif %}
{%- endif %}

{%- if repl_override != 'x' %}
{%- set replicas = hdfs_repl_override %}
{%- endif %}

{%- set config_hdfs_site = gc.get('hdfs-site', pc.get('hdfs-site', {})) %}

{%- set hdfs = {} %}
{%- do hdfs.update({ 'local_disks'                 : local_disks,
                     'namenode_host'               : namenode_host,
                     'datanode_hosts'              : datanode_hosts,
                     'namenode_port'               : namenode_port,
                     'namenode_http_port'          : namenode_http_port,
                     'secondarynamenode_http_port' : secondarynamenode_http_port,
                     'replicas'                    : replicas,
                     'datanode_count'              : datanode_count,
                     'config_hdfs_site'            : config_hdfs_site,
                     'tmp_dir'                     : tmp_dir,
                     'load'                        : load,
                   }) %}
