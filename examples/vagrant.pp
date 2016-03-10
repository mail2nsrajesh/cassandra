if $::osfamily == 'RedHat' and $::operatingsystemmajrelease == 7 {
    $service_systemd = true
} elsif $::operatingsystem == 'Debian' and $::operatingsystemmajrelease == 8 {
    $service_systemd = true
} else {
    $service_systemd = false
}

if $::osfamily == 'RedHat' {
    $cassandra_optutils_package = 'cassandra22-tools'
    $cassandra_package = 'cassandra22'
    $version = '2.2.5-1'
} else {
    $cassandra_optutils_package = 'cassandra-tools'
    $cassandra_package = 'cassandra'
    $version = '2.2.5'
}

class { 'cassandra::java': } ->
class { 'cassandra::datastax_repo': } ->
class { 'cassandra':
  cassandra_9822              => true,
  commitlog_directory_mode    => '0770',
  data_file_directories_mode  => '0770',
  listen_interface            => 'lo',
  package_ensure              => $version,
  package_name                => $cassandra_package,
  rpc_interface               => 'lo',
  saved_caches_directory_mode => '0770',
  service_systemd             => $service_systemd
}

class { 'cassandra::optutils':
  package_ensure => $version,
  package_name   => $cassandra_optutils_package,
  require        => Class['cassandra']
}

$simple_strategy_map = {
  keyspace_class     => 'SimpleStrategy',
  replication_factor => 3
}

$network_topology_strategy = {
  keyspace_class => 'NetworkTopologyStrategy',
  dc1            => 3,
  dc2            => 2
}

$keyspaces = {
  'Excelsior' => {
    ensure          => present,
    replication_map => $simple_strategy_map,
    durable_writes  => false
  },
  'Excalibur' => {
    ensure          => present,
    replication_map => $network_topology_strategy,
    durable_writes  => true
  }
}

class { 'cassandra::schema':
  keyspaces => $keyspaces
}