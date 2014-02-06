{% set p  = salt['pillar.get']('hadoop', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('hadoop', {}) %}
{% set gc = g.get('config', {}) %}

{%- set versions = {} %}
{%- set default_dist_id = 'apache-1.2.1' %}
{%- set dist_id = g.get('version', p.get('version', default_dist_id)) %}

{%- set versions = { 'apache-1.2.1' : { 'version'       : '1.2.1',
                                        'version_name'  : 'hadoop-1.2.1',
                                        'source_url'    : salt['grains.get']('hadoop:source_url', 'http://www.us.apache.org/dist/hadoop/common/hadoop-1.2.1/hadoop-1.2.1-bin.tar.gz'),
                                        'major_version' : '1'
                                      },
                     'apache-2.2.0' : { 'version'       : '2.2.0',
                                        'version_name'  : 'hadoop-2.2.0',
                                        'source_url'    : salt['grains.get']('hadoop:source_url', 'http://www.us.apache.org/dist/hadoop/common/hadoop-2.2.0/hadoop-2.2.0.tar.gz'),
                                        'major_version' : '2'
                                      },
                     'hdp-2.2.0'    : { 'version'       : '2.2.0.2.0.6.0-76',
                                        'version_name'  : 'hadoop-2.2.0.2.0.6.0-76',
                                        'source_url'    : salt['grains.get']('hadoop:source_url', 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.0.6.0/tars/hadoop-2.2.0.2.0.6.0-76.tar.gz'),
                                        'major_version' : '2'
                                      },
                     'hdp-1.3.0'    : { 'version'       : '1.2.0.1.3.3.0-58',
                                        'version_name'  : 'hadoop-1.2.0.1.3.3.0-58',
                                        'source_url'    : salt['grains.get']('hadoop:source_url', 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/updates/1.3.3.0/tars/hadoop-1.2.0.1.3.3.0-58.tar.gz'),
                                        'major_version' : '1'
                                      },
                     'cdh-4.5.0'    : { 'version'       : '2.0.0-cdh4.5.0',
                                        'version_name'  : 'hadoop-2.0.0-cdh4.5.0',
                                        'source_url'    : salt['grains.get']('hadoop:source_url', 'http://archive.cloudera.com/cdh4/cdh/4/hadoop-2.0.0-cdh4.5.0.tar.gz'),
                                        'major_version' : '2'
                                      },
                     'cdh-4.5.0-mr1': { 'version'       : '2.0.0-cdh4.5.0',
                                        'version_name'  : 'hadoop-2.0.0-cdh4.5.0',
                                        'source_url'    : salt['grains.get']('hadoop:source_url', 'http://archive.cloudera.com/cdh4/cdh/4/hadoop-2.0.0-cdh4.5.0.tar.gz'),
                                        'major_version' : '1',
                                        'cdhmr1'        : True
                                      }
                   }%}

{%- set version_info     = versions.get(dist_id, versions['apache-1.2.1']) %}
{%- set alt_home         = salt['pillar.get']('hadoop:prefix', '/usr/lib/hadoop') %}
{%- set real_home        = '/usr/lib/' + version_info['version_name'] %}
{%- set alt_config       = gc.get('directory', pc.get('directory', '/etc/hadoop/conf')) %}
{%- set real_config      = alt_config + '-' + version_info['version'] %}
{%- set real_config_dist = alt_config + '.dist' %}

{%- if version_info['major_version'] == '1' %}
{%- set dfs_cmd = alt_home + '/bin/hadoop dfs' %}
{%- else %}
{%- set dfs_cmd = alt_home + '/bin/hdfs dfs' %}
{%- endif %}

{%- set java_home        = salt['pillar.get']('java_home', '/usr/lib/java') %}
{%- set config_core_site = gc.get('core-site-xml', pc.get('core-site-xml', "")) %}

{%- set hadoop = {} %}
{%- do hadoop.update( {   'dist_id'          : dist_id,
                          'cdhmr1'           : version_info.get('cdhmr1', False),
                          'version'          : version_info['version'],
                          'version_name'     : version_info['version_name'],
                          'source_url'       : version_info['source_url'],
                          'major_version'    : version_info['major_version'],
                          'alt_home'         : alt_home,
                          'real_home'        : real_home,
                          'alt_config'       : alt_config,
                          'real_config'      : real_config,
                          'real_config_dist' : real_config_dist,
                          'dfs_cmd'          : dfs_cmd,
                          'java_home'        : java_home,
                          'config_core_site' : config_core_site,
                      }) %}
