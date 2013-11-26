{%- set versions = {} %}
{%- set hadoop_pillar = pillar.get('hadoop', {}) %}

{%- set default_version = salt['pillar.get']('hadoop_version', 'apache-1.2.1') %}
{%- set dist_id = salt['grains.get']('hadoop_version', default_dist_id) %}

{%- set versions = { 'apache-1.2.1' : { 'version'       : '1.2.1',
                                        'version_name'  : 'hadoop-1.2.1',
                                        'tarball'       : 'hadoop-1.2.1-bin.tar.gz',
                                        'source_url'    : 'http://www.us.apache.org/dist/hadoop/common/hadoop-1.2.1/hadoop-1.2.1-bin.tar.gz',
                                        'source_hash'   : 'md5=d9d9e9a5343cb741d78a3d4c22d0bb0f',
                                        'major_version' : '1'
                                      },
                     'apache-2.2.0' : { 'version'       : '2.2.0',
                                        'version_name'  : 'hadoop-2.2.0',
                                        'tarball'       : 'hadoop-2.2.0.tar.gz',
                                        'source_url'    : 'http://www.us.apache.org/dist/hadoop/common/hadoop-2.2.0/hadoop-2.2.0.tar.gz',
                                        'source_hash'   : 'md5=25f27eb0b5617e47c032319c0bfd9962',
                                        'major_version' : '2'
                                      },
                     'hdp-2.2.0'    : { 'version'       : '2.2.0.2.0.6.0-76',
                                        'version_name'  : 'hadoop-2.2.0.2.0.6.0-76',
                                        'tarball'       : 'hadoop-2.2.0.2.0.6.0-76.tar.gz',
                                        'source_url'    : 'http://public-repo-1.hortonworks.com/HDP/centos6/2.x/updates/2.0.6.0/tars/hadoop-2.2.0.2.0.6.0-76.tar.gz',
                                        'source_hash'   : 'md5=598e46e77c333d8a66a3cf083db7ff57',
                                        'major_version' : '2'
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
{%- do hadoop.update( {   'version'          : version_info['version'],
                          'version_name'     : version_info['version_name'],
                          'source_url'       : version_info['source_url'],
                          'source_hash'      : version_info['source_hash'],
                          'major_version'    : version_info['major_version'],
                          'alt_home'         : alt_home,
                          'real_home'        : real_home,
                          'alt_config'       : alt_config,
                          'real_config'      : real_config,
                          'real_config_dist' : real_config_dist,
                          'tarball_path'     : salt['pillar.get']('downloads_path', '/tmp') + '/' +version_info['tarball'],
                          'namenode_host'    : namenode_host,
                          'dfs_cmd'          : dfs_cmd
                      }) %}
