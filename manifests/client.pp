define openvpn::client (
    $remote,
    $certname,
    $device   = 'tap',
    $device_id = undef,
    $br_device = 'br2',
    $server_ip = ::ipaddress_eth1,
    $port = '1194',
    $netmask = '255.255.0.0',
    $user = 'nobody',
    $group = 'nogroup',
    $max_clients = '200',
    $push_dns_ip = undef,
  ){
  # directory for certificate authority called ca_name
  $config_dir = "/etc/openvpn/openvpn-${name}-conf.d"
  # main client instance config file
  file { "/etc/openvpn/openvpn-${name}.conf":
    ensure  => present,
    content => template('openvpn/openvpn_client.conf.erb'),
    require => Package['openvpn'],
    notify  => Service['openvpn'],
  }
  # config dir resource
  file { $config_dir:
    ensure  => directory,
    require => Package['openvpn'],
  }
  # key directory
  file { "${config_dir}/keys":
    ensure  => directory,
    require => Package['openvpn'],
  }
  # client instace tap device resource
  if $device == 'tap' {
    file { "/etc/network/interfaces.d/openvpn-${br_device}.conf":
      ensure  => present,
      content => template('openvpn/openvpn-network.config.erb'),
      require => Package['openvpn'],
      notify  => Service['openvpn'],
    }
  }
}
