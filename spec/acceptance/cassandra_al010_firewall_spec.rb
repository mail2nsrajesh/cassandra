require 'spec_helper_acceptance'

describe 'cassandra class' do
  firewall_config_pp = <<-EOS
    if $::osfamily == 'RedHat' {
      $cassandra_package = 'cassandra21'
      $version = '2.1.13-1'
    } else {
      $cassandra_package = 'cassandra'
      $version = '2.1.13'
    }

    class { 'cassandra':
      cassandra_9822              => true,
      dc                          => 'LON',
      package_ensure              => $version,
      package_name                => $cassandra_package,
      rack                        => 'R101',
      settings                    => {
        'authenticator'               => 'PasswordAuthenticator',
        'cluster_name'                => 'MyCassandraCluster',
        'commitlog_directory'         => '/var/lib/cassandra/commitlog',
        'commitlog_sync'              => 'periodic',
        'commitlog_sync_period_in_ms' => 10000,
        'data_file_directories'       => ['/var/lib/cassandra/data'],
        'endpoint_snitch'             => 'GossipingPropertyFileSnitch',
        'listen_address'              => $::ipaddress,
        'partitioner'                 => 'org.apache.cassandra.dht.Murmur3Partitioner',
        'saved_caches_directory'      => '/var/lib/cassandra/saved_caches',
        'seed_provider'               => [
          {
            'class_name' => 'org.apache.cassandra.locator.SimpleSeedProvider',
            'parameters' => [
              {
                'seeds' => $::ipaddress,
              },
            ],
          },
        ],
        'start_native_transport'      => true,
      },
    }

    include '::cassandra::datastax_agent'

    # This really sucks but Docker, CentOS 6 and iptables don't play nicely
    # together.  Therefore we can't test the firewall on this platform :-(
    if $::operatingsystem != CentOS and $::operatingsystemmajrelease != 6 {
      include '::cassandra::firewall_ports'
    }
  EOS

  describe '########### Firewall configuration.' do
    it 'should work with no errors' do
      apply_manifest(firewall_config_pp, catch_failures: true)
    end
  end
end