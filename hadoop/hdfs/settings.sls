{%- set p  = salt['pillar.get']('hdfs', {}) %}
{%- set pc = p.get('config', {}) %}
{%- set g  = salt['grains.get']('hdfs', {}) %}
{%- set gc = g.get('config', {}) %}

# TODO: https://github.com/accumulo/hadoop-formula/issues/1 'Replace direct mine.get calls'
{%- set namenode_target     = p.get('namenode_target', 'roles:hadoop_master') %}
{%- set datanode_target     = p.get('datanode_target', 'roles:hadoop_slave') %}
# this is a deliberate duplication as to not re-import hadoop/settings multiple times
{%- set targeting_method    = salt['grains.get']('hadoop:targeting_method', salt['pillar.get']('hadoop:targeting_method', 'grain')) %}
{%- set namenode_host       = salt['mine.get'](namenode_target, 'network.interfaces', expr_form=targeting_method)|first %}
{%- set datanode_hosts      = salt['mine.get'](datanode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set datanode_count      = datanode_hosts|count() %}
{%- set namenode_port       = gc.get('namenode_port', pc.get('namenode_port', '8020')) %}
{%- set namenode_http_port  = gc.get('namenode_http_port', pc.get('namenode_http_port', '50070')) %}
{%- set secondarynamenode_http_port  = gc.get('secondarynamenode_http_port', pc.get('secondarynamenode_http_port', '50090')) %}
{%- set local_disks         = salt['grains.get']('hdfs_data_disks', ['/data']) %}
{%- set hdfs_repl_override  = gc.get('replication', pc.get('replication', 'x')) %}
{%- set load                = salt['grains.get']('hdfs_load', salt['pillar.get']('hdfs_load', {})) %}

# Todo: this might be a candidate for pillars/grains
# {%- set tmp_root        = local_disks|first() %}
{%- set tmp_dir         = '/tmp' %}

{%- if hdfs_repl_override == 'x' %}
{%- if datanode_count >= 3 %}
{%- set replicas = '3' %}
{%- elif datanode_count == 2 %}
{%- set replicas = '2' %}
{%- else %}
{%- set replicas = '1' %}
{%- endif %}
{%- endif %}

{%- if hdfs_repl_override != 'x' %}
{%- set replicas = hdfs_repl_override %}
{%- endif %}

{%- set config_hdfs_site = gc.get('hdfs-site', pc.get('hdfs-site', {})) %}

{%- set is_namenode = salt['match.' ~ targeting_method](namenode_target) %}
{%- set is_datanode = salt['match.' ~ targeting_method](datanode_target) %}

{%- set hdfs = {} %}
{%- do hdfs.update({ 'local_disks'                 : local_disks,
                     'namenode_host'               : namenode_host,
                     'datanode_hosts'              : datanode_hosts,
                     'namenode_port'               : namenode_port,
                     'namenode_http_port'          : namenode_http_port,
                     'is_namenode'                 : is_namenode,
                     'is_datanode'                 : is_datanode,
                     'secondarynamenode_http_port' : secondarynamenode_http_port,
                     'replicas'                    : replicas,
                     'datanode_count'              : datanode_count,
                     'config_hdfs_site'            : config_hdfs_site,
                     'tmp_dir'                     : tmp_dir,
                     'load'                        : load,
                   }) %}
