{% set p  = salt['pillar.get']('yarn', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('yarn', {}) %}
{% set gc = g.get('config', {}) %}

{%- set resourcetracker_port        = gc.get('resourcetracker_port', pc.get('resourcetracker_port', '8031')) %}
{%- set scheduler_port              = gc.get('scheduler_port', pc.get('scheduler_port', '8030')) %}
{%- set resourcemanager_port        = gc.get('resourcemanager_port', pc.get('resourcemanager_port', '8032')) %}
{%- set resourcemanager_webapp_port = gc.get('resourcemanager_webapp_port', pc.get('resourcemanager_webapp_port', '8088')) %}
{%- set resourcemanager_admin_port  = gc.get('resourcemanager_admin_port', pc.get('resourcemanager_admin_port', '8033')) %}
{%- set nodemanager_port            = gc.get('nodemanager_port', pc.get('nodemanager_port', '50024')) %}
{%- set nodemanager_webapp_port     = gc.get('nodemanager_webapp_port', pc.get('nodemanager_webapp_port', '50025')) %}
{%- set nodemanager_localizer_port  = gc.get('nodemanager_localizer_port', pc.get('nodemanager_localizer_port', '50026')) %}

{%- set resourcemanager_host        = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() -%}
{%- set local_disks                 = salt['grains.get']('yarn_data_disks', ['/yarn_data']) %}
{%- set config_yarn_site            = gc.get('yarn-site', pc.get('yarn-site', {})) %}

{%- set yarn = {} %}
{%- do yarn.update({ 'resourcetracker_port'        : resourcetracker_port,
                     'scheduler_port'              : scheduler_port,
                     'resourcemanager_port'        : resourcemanager_port,
                     'resourcemanager_webapp_port' : resourcemanager_webapp_port,
                     'resourcemanager_admin_port'  : resourcemanager_admin_port,
                     'resourcemanager_host'        : resourcemanager_host,
                     'nodemanager_port'            : nodemanager_port,
                     'nodemanager_webapp_port'     : nodemanager_webapp_port,
                     'nodemanager_localizer_port'  : nodemanager_localizer_port,
                     'local_disks'                 : local_disks,
                     'first_local_disk'            : local_disks|sort()|first(),
                     'config_yarn_site'            : config_yarn_site,
                   }) %}
