{% set p  = salt['pillar.get']('hadoop', {}) %}
{% set pc = p.get('config', {}) %}
{% set g  = salt['grains.get']('hadoop', {}) %}
{% set gc = g.get('config', {}) %}

{%- set versions = {} %}

{%- set default_dist_id = 'apache-1.2.1' %}
{%- set dist_id = g.get('version', p.get('version', default_dist_id)) %}

{%- set versions = { 'apache-1.2.1' : { 'version'       : '1.2.1',
                                        'version_name'  : 'hadoop-1.2.1',
                                        'source_url'    : salt['grains.get']('hadoop_source', 'http://www.us.apache.org/dist/hadoop/common/hadoop-1.2.1/hadoop-1.2.1-bin.tar.gz'),
                                        'major_version' : '1'
                                      },
                     'apache-2.2.0' : { 'version'       : '2.2.0',
                                        'version_name'  : 'hadoop-2.2.0',
                                        'source_url'    : salt['grains.get']('hadoop_source', 'http://www.us.apache.org/dist/hadoop/common/hadoop-2.2.0/hadoop-2.2.0.tar.gz'),
                                        'major_version' : '2'
                                      },
                     'hdp-2.2.0'    : { 'version'       : '2.2.0.2.0.6.0-76',
                                        'version_name'  : 'hadoop-2.2.0.2.0.6.0-76',
                                        'source_url'    : salt['grains.get']('hadoop_source', 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.0.6.0/tars/hadoop-2.2.0.2.0.6.0-76.tar.gz'),
                                        'major_version' : '2'
                                      },
                     'hdp-1.3.0'    : { 'version'       : '1.2.0.1.3.3.0-58',
                                        'version_name'  : 'hadoop-1.2.0.1.3.3.0-58',
                                        'source_url'    : salt['grains.get']('hadoop_source', 'http://public-repo-1.hortonworks.com/HDP/centos6/1.x/updates/1.3.3.0/tars/hadoop-1.2.0.1.3.3.0-58.tar.gz'),
                                        'major_version' : '1'
                                      }
                   }%}

{%- set version_info     = versions.get(dist_id, versions['apache-1.2.1']) %}
{%- set alt_home         = salt['pillar.get']('hadoop:prefix', '/usr/lib/hadoop') %}
{%- set real_home        = '/usr/lib/' + version_info['version_name'] %}
{%- set alt_config       = salt['pillar.get']('hadoop:config:directory', '/etc/hadoop/conf') %}
{%- set real_config      = alt_config + '-' + version_info['version'] %}
{%- set real_config_dist = alt_config + '.dist' %}

# TODO: https://github.com/accumulo/hadoop-formula/issues/1 'Replace direct mine.get calls'
{% set namenode_host = salt['mine.get']('roles:hadoop_master', 'network.interfaces', 'grain').keys()|first() -%}

{%- if version_info['major_version'] == '1' %}
{%- set dfs_cmd = alt_home + '/bin/hadoop dfs' %}
{%- else %}
{%- set dfs_cmd = alt_home + '/bin/hdfs dfs' %}
{%- endif %}

{%- set hadoop = {} %}
{%- do hadoop.update( {   'dist_id'          : dist_id,
                          'version'          : version_info['version'],
                          'version_name'     : version_info['version_name'],
                          'source_url'       : version_info['source_url'],
                          'major_version'    : version_info['major_version'],
                          'alt_home'         : alt_home,
                          'real_home'        : real_home,
                          'alt_config'       : alt_config,
                          'real_config'      : real_config,
                          'real_config_dist' : real_config_dist,
                          'namenode_host'    : namenode_host,
                          'dfs_cmd'          : dfs_cmd
                      }) %}
