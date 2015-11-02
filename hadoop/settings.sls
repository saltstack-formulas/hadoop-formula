{% set p  = salt['pillar.get']('hadoop', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('hadoop', {}) %}
{% set gc = g.get('config', {}) %}

{%- set versions = {} %}
{%- set default_dist_id = 'apache-2.2.0' %}
{%- set dist_id = g.get('version', p.get('version', default_dist_id)) %}

{%- set default_versions = { 'apache-1.2.1' : { 'version'       : '1.2.1',
                                        'version_name'  : 'hadoop-1.2.1',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://apache.osuosl.org/hadoop/common/hadoop-1.2.1/hadoop-1.2.1-bin.tar.gz')),
                                        'major_version' : '1'
                                      },
                     'apache-2.2.0' : { 'version'       : '2.2.0',
                                        'version_name'  : 'hadoop-2.2.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.apache.org/dist/hadoop/core/hadoop-2.2.0/hadoop-2.2.0.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'apache-2.3.0' : { 'version'       : '2.3.0',
                                        'version_name'  : 'hadoop-2.3.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.apache.org/dist/hadoop/core/hadoop-2.3.0/hadoop-2.3.0.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'apache-2.4.0' : { 'version'       : '2.4.0',
                                        'version_name'  : 'hadoop-2.4.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.apache.org/dist/hadoop/core/hadoop-2.4.0/hadoop-2.4.0.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'apache-2.5.2' : { 'version'       : '2.5.2',
                                        'version_name'  : 'hadoop-2.5.2',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://apache.osuosl.org/hadoop/core/hadoop-2.5.2/hadoop-2.5.2.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'apache-2.6.0' : { 'version'       : '2.6.0',
                                        'version_name'  : 'hadoop-2.6.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.apache.org/dist/hadoop/core/hadoop-2.6.0/hadoop-2.6.0.tar.gz')),
                                        'major_version' : '2',
                                      },
                     'hdp-2.7.1'    : { 'version'       : '2.7.1.2.3.2.0-2950',
                                        'version_name'  : 'hadoop-2.7.1.2.3.2.0-2950',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.3.2.0/tars/hadoop-2.7.1.2.3.2.0-2950.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'hdp-2.6.0'    : { 'version'       : '2.6.0.2.2.6.0-2800',
                                        'version_name'  : 'hadoop-2.6.0.2.2.6.0-2800',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.2.6.0/tars/hadoop-2.6.0.2.2.6.0-2800.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'hdp-2.4.0'    : { 'version'       : '2.4.0.2.1.10.0-881',
                                        'version_name'  : 'hadoop-2.4.0.2.1.10.0-881',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.1.10.0/tars/hadoop-2.4.0.2.1.10.0-881.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'hdp-2.2.0'    : { 'version'       : '2.2.0.2.0.6.0-76',
                                        'version_name'  : 'hadoop-2.2.0.2.0.6.0-76',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.0.6.0/tars/hadoop-2.2.0.2.0.6.0-76.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'hdp-1.3.0'    : { 'version'       : '1.2.0.1.3.10.0-24',
                                        'version_name'  : 'hadoop-1.2.0.1.3.10.0-24',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/updates/1.3.10.0/tars/hadoop-1.2.0.1.3.10.0-24.tar.gz')),
                                        'major_version' : '1'
                                      },
                     'cdh-4.5.0'    : { 'version'       : '2.0.0-cdh4.5.0',
                                        'version_name'  : 'hadoop-2.0.0-cdh4.5.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.cloudera.com/cdh4/cdh/4/hadoop-2.0.0-cdh4.5.0.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'cdh-4.5.0-mr1': { 'version'       : '2.0.0-cdh4.5.0',
                                        'version_name'  : 'hadoop-2.0.0-cdh4.5.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.cloudera.com/cdh4/cdh/4/hadoop-2.0.0-cdh4.5.0.tar.gz')),
                                        'major_version' : '1',
                                        'cdhmr1'        : True
                                      },
                     'cdh-4.6.0'    : { 'version'       : '2.0.0-cdh4.6.0',
                                        'version_name'  : 'hadoop-2.0.0-cdh4.6.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.cloudera.com/cdh4/cdh/4/hadoop-2.0.0-cdh4.6.0.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'cdh-4.6.0-mr1': { 'version'       : '2.0.0-cdh4.6.0',
                                        'version_name'  : 'hadoop-2.0.0-cdh4.6.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.cloudera.com/cdh4/cdh/4/hadoop-2.0.0-cdh4.6.0.tar.gz')),
                                        'major_version' : '1',
                                        'cdhmr1'        : True
                                      },
                     'cdh-5.0.0'    : { 'version'       : '2.3.0-cdh5.0.0',
                                        'version_name'  : 'hadoop-2.3.0-cdh5.0.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.cloudera.com/cdh5/cdh/5/hadoop-2.3.0-cdh5.0.0.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'cdh-5.0.0-mr1': { 'version'       : '2.3.0-cdh5.0.0',
                                        'version_name'  : 'hadoop-2.3.0-cdh5.0.0',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive.cloudera.com/cdh5/cdh/5/hadoop-2.3.0-cdh5.0.0.tar.gz')),
                                        'major_version' : '1',
                                        'cdhmr1'        : True
                                      },
                     'cdh-5.3.1'    : { 'version'       : '2.5.0-cdh5.3.1',
                                        'version_name'  : 'hadoop-2.5.0-cdh5.3.1',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive-primary.cloudera.com/cdh5/cdh/5/hadoop-2.5.0-cdh5.3.1.tar.gz')),
                                        'major_version' : '2'
                                      },
                     'cdh-5.3.1-mr1': { 'version'       : '2.5.0-cdh5.3.1',
                                        'version_name'  : 'hadoop-2.5.0-cdh5.3.1',
                                        'source_url'    : g.get('source_url', p.get('source_url', 'http://archive-primary.cloudera.com/cdh5/cdh/5/hadoop-2.5.0-cdh5.3.1.tar.gz')),
                                        'major_version' : '1',
                                        'cdhmr1'        : True
                                      },
                   }%}

{%- set versions         = p.get('versions', default_versions) %}
{%- set version_info     = versions.get(dist_id, versions['apache-1.2.1']) %}
{%- set alt_home         = salt['pillar.get']('hadoop:prefix', '/usr/lib/hadoop') %}
{%- set real_home        = '/usr/lib/' + version_info['version_name'] %}
{%- set alt_config       = gc.get('directory', pc.get('directory', '/etc/hadoop/conf')) %}
{%- set real_config      = alt_config + '-' + version_info['version'] %}
{%- set real_config_dist = alt_config + '.dist' %}
{%- set default_log_root = '/var/log/hadoop' %}
{%- set log_root         = gc.get('log_root', pc.get('log_root', default_log_root)) %}
{%- set initscript       = 'hadoop.init' %}
{%- set targeting_method = g.get('targeting_method', p.get('targeting_method', 'grain')) %}

{%- if version_info['major_version'] == '1' %}
{%- set dfs_cmd = alt_home + '/bin/hadoop dfs' %}
{%- set dfsadmin_cmd = alt_home + '/bin/hadoop dfsadmin' %}
{%- else %}
{%- set dfs_cmd = alt_home + '/bin/hdfs dfs' %}
{%- set dfsadmin_cmd = alt_home + '/bin/hdfs dfsadmin' %}
{%- endif %}

{%- set java_home        = salt['grains.get']('java_home', salt['pillar.get']('java_home', '/usr/lib/java')) %}
{%- set config_core_site = gc.get('core-site', pc.get('core-site', {})) %}

{%- set hadoop = {} %}
{%- do hadoop.update( {   'dist_id'          : dist_id,
                          'cdhmr1'           : version_info.get('cdhmr1', False),
                          'version'          : version_info['version'],
                          'version_name'     : version_info['version_name'],
                          'source_url'       : version_info['source_url'],
                          'major_version'    : version_info['major_version']|string(),
                          'alt_home'         : alt_home,
                          'real_home'        : real_home,
                          'alt_config'       : alt_config,
                          'real_config'      : real_config,
                          'real_config_dist' : real_config_dist,
                          'initscript'       : initscript,
                          'dfs_cmd'          : dfs_cmd,
                          'dfsadmin_cmd'     : dfsadmin_cmd,
                          'java_home'        : java_home,
                          'log_root'         : log_root,
                          'default_log_root' : default_log_root,
                          'config_core_site' : config_core_site,
                          'targeting_method': targeting_method,
                      }) %}
