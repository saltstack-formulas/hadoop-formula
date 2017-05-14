{%- set p  = salt['pillar.get']('hdfs', {}) %}
{%- set pc = p.get('config', {}) %}
{%- set g  = salt['grains.get']('hdfs', {}) %}
{%- set gc = g.get('config', {}) %}

{%- set namenode_target              = g.get('namenode_target', p.get('namenode_target', 'roles:hadoop_master')) %}
{%- set primary_namenode_target      = g.get('primary_namenode_target', p.get('primary_namenode_target', 'roles:hdfs_namenode1')) %}
{%- set secondary_namenode_target    = g.get('secondary_namenode_target', p.get('secondary_namenode_target', 'roles:hdfs_namenode2')) %}
{%- set datanode_target              = g.get('datanode_target', p.get('datanode_target', 'roles:hadoop_slave')) %}
{%- set journalnode_target           = g.get('journalnode_target', p.get('journalnode_target', 'roles:hdfs_journalnode')) %}
# this is a deliberate duplication as to not re-import hadoop/settings multiple times
{%- set targeting_method             = salt['grains.get']('hadoop:targeting_method', salt['pillar.get']('hadoop:targeting_method', 'grain')) %}

{%- set namenode_port                = gc.get('namenode_port', pc.get('namenode_port', '8020')) %}
{%- set namenode_http_port           = gc.get('namenode_http_port', pc.get('namenode_http_port', '50070')) %}
{%- set secondarynamenode_http_port  = gc.get('secondarynamenode_http_port', pc.get('secondarynamenode_http_port', '50090')) %}
{%- set local_disks                  = salt['grains.get']('hdfs_data_disks', ['/data']) %}
{%- set load                         = salt['grains.get']('hdfs_load', salt['pillar.get']('hdfs_load', {})) %}
{%- set ha_cluster_id                = salt['grains.get']('ha_cluster_id', salt['pillar.get']('ha_cluster_id', None)) %}
{%- set ha_namenode_port             = gc.get('ha_namenode_port', pc.get('ha_namenode_port', namenode_port)) %}
{%- set ha_journal_port              = gc.get('ha_journal_port', pc.get('ha_journal_port', '8485')) %}
{%- set ha_namenode_http_port        = gc.get('ha_namenode_http_port', pc.get('ha_namenode_http_port', namenode_http_port)) %}

{%- set config_hdfs_site             = gc.get('hdfs-site', pc.get('hdfs-site', {})) %}

{%- set minion_hosts                 = [salt['network.get_hostname'](),
                                        grains['fqdn'],
                                        grains['nodename']] + salt['network.ip_addrs']() %}

{%- set is_clusters                  = True if p.get('clusters') else False %}                               

{%- set pillar_cluster_id            = [] %}

{%- if is_clusters and ha_cluster_id == None %}
  {%- for cluster_name, cluster_value in p.clusters.items() %}
    {%- set hdfs_hosts = cluster_value.get('namenode_hosts', []) + 
                         cluster_value.get('datanode_hosts', []) + 
                         cluster_value.get('journalnode_hosts', []) %}  
    {%- do hdfs_hosts.append(cluster_value.get('primary_namenode_host', '')) %}
    {%- for minion_host in minion_hosts %}
      {%- if minion_host in hdfs_hosts %}
        {%- do pillar_cluster_id.append(cluster_name) %}
        {%- break %}
      {%- endif %}
    {%- endfor %}
    {%- if pillar_cluster_id %}
      {%- break %}
    {%- endif %}
  {%- endfor %}
{%- endif %}

{%- if pillar_cluster_id %}
  {%- set ha_cluster_id = pillar_cluster_id[0] %}
{%- endif %}

{%- if is_clusters and ha_cluster_id != None %}
  {%- set namenode_hosts = p.clusters.get(ha_cluster_id, {}).get('namenode_hosts', []) %}
  {%- set primary_namenode_host = p.clusters.get(ha_cluster_id, {}).get('primary_namenode_host', '') %}
  {%- set datanode_hosts = p.clusters.get(ha_cluster_id, {}).get('datanode_hosts', []) %}
  {%- set journalnode_hosts = p.clusters.get(ha_cluster_id, {}).get('journalnode_hosts', []) %}
{%- else %}
  {%- set namenode_hosts        = g.get('namenode_hosts', p.get('namenode_hosts', salt['mine.get'](namenode_target, 'network.interfaces', expr_form=targeting_method).keys()|sort())) %}
  {%- set datanode_hosts        = g.get('datanode_hosts', p.get('datanode_hosts', salt['mine.get'](datanode_target, 'network.interfaces', expr_form=targeting_method).keys())) %}
  {%- set journalnode_hosts     = g.get('journalnode_hosts', p.get('journalnode_hosts', salt['mine.get'](journalnode_target, 'network.interfaces', expr_form=targeting_method).keys()|sort())) %}
  {%- set primary_namenode_host = g.get('primary_namenode_host', p.get('primary_namenode_host')) %}
  {%- if not primary_namenode_host %}
    {%- set primary_namenode_host = salt['mine.get'](primary_namenode_target, 'network.interfaces', expr_form=targeting_method).keys() %}
    {%- if primary_namenode_host|count > 0 %}
      {%- set primary_namenode_host = primary_namenode_host|first() %}
    {%- endif %}
  {%- endif %}
{%- endif %}

{%- if ha_cluster_id == None %}
  {%- set ha_cluster_id = 'hdfscluster' %}
{%- endif %}

{%- set namenode_count = namenode_hosts|count() %}
{%- if namenode_count > 0 %}
  {%- set namenode_host = namenode_hosts|first()|join() %}
{%- endif %}

{%- set datanode_count    = datanode_hosts|count() %}
{%- set journalnode_count = journalnode_hosts|count() %}

{%- set quorum_connection_string = "" %}

{%- if journalnode_count > 0 %}
  {%- set connection_string_list = [] %}
  {%- for n in journalnode_hosts %}
    {%- do connection_string_list.append( n + ':' + ha_journal_port | string() ) %}
  {%- endfor %}
  {%- set quorum_connection_string = connection_string_list | join(';')%}
{%- endif %}
# Todo: this might be a candidate for pillars/grains
# {%- set tmp_root        = local_disks|first() %}
{%- set tmp_dir                  = '/tmp' %}

{%- set replicas                 = gc.get('replication', pc.get('replication', datanode_count % 4 if datanode_count < 4 else 3 )) %}

{%- set is_namenode              = salt['match.' ~ targeting_method](namenode_target) %}
{%- set is_primary_namenode      = salt['match.' ~ targeting_method](primary_namenode_target) %}
{%- set is_secondary_namenode    = salt['match.' ~ targeting_method](secondary_namenode_target) %}
{%- set is_journalnode           = salt['match.' ~ targeting_method](journalnode_target) %}
{%- set is_datanode              = salt['match.' ~ targeting_method](datanode_target) %}

{%- set is_datanode_in_pillar    = [] %}
{%- set is_namenode_in_pillar    = [] %}
{%- set is_journalnode_in_pillar = [] %}

{%- if not is_datanode %}
  {%- for minion_host in minion_hosts %}
    {%- if minion_host in datanode_hosts %}
      {%- do is_datanode_in_pillar.append(True) %}
      {% break %}
    {%- endif %}
  {%- endfor %}
{%- endif %}

{%- if not is_namenode %}
  {%- for minion_host in minion_hosts %}
    {%- if minion_host in namenode_hosts %}
      {%- do is_namenode_in_pillar.append(True) %}
      {% break %}
    {%- endif %}
  {%- endfor %}
{%- endif %}

{%- if not is_journalnode %}
  {%- for minion_host in minion_hosts %}
    {%- if minion_host in journalnode_hosts %}
      {%- do is_journalnode_in_pillar.append(True) %}
      {% break %}
    {%- endif %}
  {%- endfor %}
{%- endif %}

{%- if is_namenode_in_pillar %}
  {%- set is_namenode = True %}
{%- endif %}

{%- if is_journalnode_in_pillar %}
  {%- set is_journalnode = True %}
{%- endif %}

{%- if is_datanode_in_pillar %}
  {%- set is_datanode = True %}
{%- endif %}

{%- set is_primary_namenode      = is_primary_namenode or primary_namenode_host in minion_hosts %}

{%- set is_secondary_namenode    = is_secondary_namenode or ( is_namenode and not is_primary_namenode ) %}

{%- set restart_on_config_change = pc.get('restart_on_config_change', False) %}

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
                     'restart_on_config_change'    : restart_on_config_change,
                     'replicas'                    : replicas,
                     'datanode_count'              : datanode_count,
                     'journalnode_count'           : journalnode_count,
                     'config_hdfs_site'            : config_hdfs_site,
                     'tmp_dir'                     : tmp_dir,
                     'load'                        : load,
                     'ha_cluster_id'               : ha_cluster_id,
                     'quorum_connection_string'    : quorum_connection_string,
                   }) %}
