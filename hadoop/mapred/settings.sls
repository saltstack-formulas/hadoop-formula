{%- from 'hadoop/hdfs/settings.sls' import hdfs with context %}
{% set p  = salt['pillar.get']('mapred', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('mapred', {}) %}
{% set gc = g.get('config', {}) %}

{%- set jobtracker_port  = gc.get('jobtracker_port', pc.get('jobtracker_port', '9001')) %}
{%- set jobtracker_http_port  = gc.get('jobtracker_http_port', pc.get('jobtracker_http_port', '50030')) %}
{%- set jobhistory_port  = gc.get('jobhistory_port', pc.get('jobhistory_port', '10020')) %}
{%- set jobhistory_webapp_port  = gc.get('jobhistory_webapp_port', pc.get('jobhistory_webapp_port', '19888')) %}
{%- set history_dir      = gc.get('history_dir', pc.get('history_dir', '/mr-history')) %}
{%- set history_intermediate_done_dir = history_dir + '/tmp' %}
{%- set history_done_dir = history_dir + '/done' %}
{%- set jobtracker_target = g.get('jobtracker_target', p.get('jobtracker_target', 'roles:hadoop_master')) %}
{%- set tasktracker_target = g.get('tasktracker_target', p.get('tasktracker_target', 'roles:hadoop_slave')) %}
{%- set targeting_method = salt['grains.get']('hadoop:targeting_method', salt['pillar.get']('hadoop:targeting_method', 'grain')) %}
{%- set ha_cluster_id               = salt['grains.get']('ha_cluster_id', salt['pillar.get']('ha_cluster_id', None)) %}

{%- set minion_hosts                = [salt['network.get_hostname'](),
                                       grains['fqdn'],
                                       grains['nodename']] + salt['network.ip_addrs']() %}

{%- set is_clusters           = True if p.get('clusters') else False %} 
{%- set pillar_cluster_id = [] %}

{%- if is_clusters and ha_cluster_id == None %}
  {%- for cluster_name, cluster_value in p.clusters.items() %}
    {%- for minion_host in minion_hosts %}
      {%- if minion_host in cluster_value.get('tasktracker_hosts', []) or
             minion_host == cluster_value.get('jobtracker_host', '') %}
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
  {%- set jobtracker_host = p.clusters.get(ha_cluster_id, {}).get('jobtracker_host', '') %}
  {%- set tasktracker_hosts = p.clusters.get(ha_cluster_id, {}).get('tasktracker_hosts', []) %}
  {%- if p.get(ha_cluster_id, {}).get('tasktrackers_on_datanodes', False) %}
    {%- set tasktracker_hosts = tasktracker_hosts + hdfs.datanode_hosts %}
  {%- endif %}
{%- else %}
  {%- set jobtracker_host  = g.get('jobtracker_host', p.get('jobtracker_host', None)) %}
  {%- if jobtracker_host == None %}
    {%- set jobtracker_host = salt['mine.get'](jobtracker_target, 'network.interfaces', expr_form=targeting_method) %}
    {%- if jobtracker_host | count() > 0 %}
      {%- set jobtracker_host  = jobtracker_host|first() %}
    {%- endif %}
  {%- endif %}
  {%- set tasktracker_hosts = g.get('tasktracker_hosts', p.get('tasktracker_hosts', [])) %}
  {%- if p.get('tasktrackers_on_datanodes', False) %}
    {%- set tasktracker_hosts = tasktracker_hosts + hdfs.datanode_hosts %}
  {%- endif %}
{%- endif %}

{%- set local_disks     = salt['grains.get']('mapred_data_disks', ['/data']) %}
{%- set config_mapred_site = gc.get('mapred-site', pc.get('mapred-site', {})) %}

{%- set is_jobtracker = salt['match.' ~ targeting_method](jobtracker_target) %}
{%- set is_tasktracker = salt['match.' ~ targeting_method](tasktracker_target) %}

{%- if not is_tasktracker %}
  {%- for minion_host in minion_hosts %}
    {%- if minion_host in tasktracker_hosts %}
      {%- set is_tasktracker_in_pillar = True %}
      {% break %}
    {%- endif %}
  {%- endfor %}
{%- endif %}

{%- set is_jobtracker = is_jobtracker or jobtracker_host in minion_hosts %}

{%- if is_tasktracker_in_pillar is defined %}
  {%- set is_tasktracker = is_tasktracker or is_tasktracker_in_pillar %}
{%- endif %}

{%- set mapred = {} %}
{%- do mapred.update({ 'jobtracker_port'               : jobtracker_port|string(),
                       'jobtracker_http_port'          : jobtracker_http_port|string(),
                       'jobhistory_port'               : jobhistory_port|string(),
                       'jobhistory_webapp_port'        : jobhistory_webapp_port|string(),
                       'jobtracker_host'               : jobtracker_host,
                       'jobtracker_target'             : jobtracker_target,
                       'tasktracker_target'            : tasktracker_target,
                       'is_jobtracker'                 : is_jobtracker,
                       'is_tasktracker'                : is_tasktracker,
                       'history_dir'                   : history_dir,
                       'history_intermediate_done_dir' : history_intermediate_done_dir,
                       'history_done_dir'              : history_done_dir,
                       'local_disks'                   : local_disks,
                       'config_mapred_site'            : config_mapred_site,
                    }) %}
