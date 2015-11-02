{%- set p  = salt['pillar.get']('hdfs', {}) %}
{%- set pc = p.get('config', {}) %}
{%- set g  = salt['grains.get']('hdfs', {}) %}
{%- set gc = g.get('config', {}) %}

{%- set namenode_target     = g.get('namenode_target', p.get('namenode_target', 'roles:hadoop_master')) %}
{%- set primary_namenode_target   = g.get('primary_namenode_target', p.get('primary_namenode_target', 'roles:hdfs_namenode1')) %}
{%- set secondary_namenode_target = g.get('secondary_namenode_target', p.get('secondary_namenode_target', 'roles:hdfs_namenode2')) %}
{%- set datanode_target     = g.get('datanode_target', p.get('datanode_target', 'roles:hadoop_slave')) %}
{%- set journalnode_target  = g.get('journalnode_target', p.get('journalnode_target', 'roles:hdfs_journalnode')) %}
# this is a deliberate duplication as to not re-import hadoop/settings multiple times
{%- set targeting_method    = salt['grains.get']('hadoop:targeting_method', salt['pillar.get']('hadoop:targeting_method', 'grain')) %}

# HA requires that you have exactly two NNs
{%- set namenode_host           = salt['mine.get'](namenode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set primary_namenode_host   = salt['mine.get'](primary_namenode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set secondary_namenode_host = salt['mine.get'](secondary_namenode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set namenode_hosts          = [] %}

# it is required to specify the namenode target and one of primary and secondary for each namenode
{%- set namenode_count = namenode_host|count() %}

# sanitize targeting results - these come as arrays, so we always pick the first
{%- if namenode_host|count() > 0 %}
{%- set namenode_host = namenode_host|first()|join() %}
{%- endif %}

{%- if primary_namenode_host|count() > 0 %}
  {%- set primary_namenode_host = primary_namenode_host|first() %}
  {%- set namenode_hosts = [primary_namenode_host] %}
  {%- if secondary_namenode_host|count() > 0 %}
    {%- set secondary_namenode_host = secondary_namenode_host|first() %}
    {%- set namenode_hosts      = [primary_namenode_host,secondary_namenode_host] %}
  {%- endif %}
{%- endif %}

{%- set datanode_hosts        = salt['mine.get'](datanode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set journalnode_hosts     = salt['mine.get'](journalnode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
{%- set datanode_count        = datanode_hosts|count() %}
{%- set journalnode_count     = journalnode_hosts|count() %}
{%- set namenode_port         = gc.get('namenode_port', pc.get('namenode_port', '8020')) %}
{%- set namenode_http_port    = gc.get('namenode_http_port', pc.get('namenode_http_port', '50070')) %}
{%- set secondarynamenode_http_port  = gc.get('secondarynamenode_http_port', pc.get('secondarynamenode_http_port', '50090')) %}
{%- set local_disks           = salt['grains.get']('hdfs_data_disks', ['/data']) %}
{%- set hdfs_repl_override    = gc.get('replication', pc.get('replication', 'x')) %}
{%- set load                  = salt['grains.get']('hdfs_load', salt['pillar.get']('hdfs_load', {})) %}
{%- set ha_cluster_id         = salt['grains.get']('ha_cluster_id', salt['pillar.get']('ha_cluster_id', 'hdfscluster')) %}
{%- set ha_namenode_port      = gc.get('ha_namenode_port', pc.get('ha_namenode_port', namenode_port)) %}
{%- set ha_journal_port       = gc.get('ha_journal_port', pc.get('ha_journal_port', '8485')) %}
{%- set ha_namenode_http_port = gc.get('ha_namenode_http_port', pc.get('ha_namenode_http_port', namenode_http_port)) %}

{%- if journalnode_count > 0 %}
{%- set quorum_connection_string = "" %}
{%- set connection_string_list = [] %}
{%- for n in journalnode_hosts %}
{%- do connection_string_list.append( n + ':' + ha_journal_port | string() ) %}
{%- endfor %}
{%- set quorum_connection_string = connection_string_list | join(';')%}
{%- else %}
{%- set quorum_connection_string = "" %}
{%- endif %}
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
{%- set is_namenode    = salt['match.' ~ targeting_method](namenode_target) %}
{%- set is_primary_namenode   = salt['match.' ~ targeting_method](primary_namenode_target) %}
{%- set is_secondary_namenode = salt['match.' ~ targeting_method](secondary_namenode_target) %}
{%- set is_journalnode = salt['match.' ~ targeting_method](journalnode_target) %}
{%- set is_datanode    = salt['match.' ~ targeting_method](datanode_target) %}

{%- set hdfs = {} %}
{%- do hdfs.update({ 'local_disks'                 : local_disks,
                     'namenode_host'               : namenode_host,
                     'namenode_hosts'              : namenode_hosts,
                     'namenode_count'              : namenode_count,
                     'datanode_hosts'              : datanode_hosts,
                     'journalnode_hosts'           : journalnode_hosts,
                     'namenode_port'               : namenode_port,
                     'ha_namenode_port'            : ha_namenode_port,
                     'namenode_http_port'          : namenode_http_port,
                     'ha_namenode_http_port'       : ha_namenode_http_port,
                     'is_namenode'                 : is_namenode,
                     'is_primary_namenode'         : is_primary_namenode,
                     'is_secondary_namenode'       : is_secondary_namenode,
                     'is_journalnode'              : is_journalnode,
                     'is_datanode'                 : is_datanode,
                     'secondarynamenode_http_port' : secondarynamenode_http_port,
                     'replicas'                    : replicas,
                     'datanode_count'              : datanode_count,
                     'journalnode_count'           : journalnode_count,
                     'config_hdfs_site'            : config_hdfs_site,
                     'tmp_dir'                     : tmp_dir,
                     'load'                        : load,
                     'ha_cluster_id'               : ha_cluster_id,
                     'quorum_connection_string'    : quorum_connection_string,
                   }) %}
