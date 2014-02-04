{% set p  = salt['pillar.get']('mapred', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('mapred', {}) %}
{% set gc = g.get('config', {}) %}

{%- set jobtracker_port  = gc.get('jobtracker_port', pc.get('jobtracker_port', '9001')) %}
{%- set jobtracker_http_port  = gc.get('jobtracker_http_port', pc.get('jobtracker_http_port', '50030')) %}
{%- set jobhistory_port  = gc.get('jobhistory_port', pc.get('jobhistory_port', '10020')) %}
{%- set jobhistory_webapp_port  = gc.get('jobhistory_webapp_port', pc.get('jobhistory_webapp_port', '19888')) %}
{%- set mapred_site_dict = gc.get('mapred-site', pc.get('mapred-site', {})) %}
{%- set history_dir      = gc.get('history_dir', pc.get('history_dir', '/mr-history')) %}
{%- set history_intermediate_done_dir = history_dir + '/tmp' %}
{%- set history_done_dir = history_dir + '/done' %}

{% set jobtracker_host = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() -%}
{% set local_disks = gc.get('mapred_data_disks', pc.get('mapred_data_disks', ['/data'])) %}

# make the settings in mapred-site.xml consistent
{%- do mapred_site_dict.update({ 'mapreduce.job.tracker': { 'value': jobtracker_host + ':' + jobtracker_port|string },
                                 'mapreduce.job.tracker.http.address': { 'value': jobtracker_host + ':' + jobtracker_http_port|string },
                                 'mapreduce.jobhistory.intermediate-done-dir': { 'value': history_intermediate_done_dir },
                                 'mapreduce.jobhistory.done-dir': { 'value': history_done_dir },
                                 'mapreduce.jobhistory.address': { 'value': jobtracker_host + ':' + jobhistory_port|string },
                                 'mapreduce.jobhistory.webapp.address' : {'value': jobtracker_host + ':' + jobhistory_webapp_port|string } }) %}

{%- set mapred = {} %}
{%- do mapred.update({ 'jobtracker_port'               : jobtracker_port,
                       'jobtracker_host'               : jobtracker_host,
                       'jobhistory_port'               : jobhistory_port,
                       'jobhistory_webapp_port'        : jobhistory_webapp_port,
                       'history_dir'                   : history_dir,
                       'history_intermediate_done_dir' : history_intermediate_done_dir,
                       'history_done_dir'              : history_done_dir,
                       'local_disks'                   : local_disks,
                    }) %}
