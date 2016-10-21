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

  $config_dir = "/etc/openvpn/openvpn-${name}-conf.d"

  file { "/etc/openvpn/openvpn-${name}.conf":
    ensure  => present,
    content => template('openvpn/openvpn_client.conf.erb'),
    require => Package['openvpn'],
    notify  => Service['openvpn'],
  }

  file { $config_dir:
    ensure  => directory,
    require => Package['openvpn'],
  }

  file { "${config_dir}/keys":
    ensure  => directory,
    require => Package['openvpn'],
  }

  if $device == 'tap' {
    file { "/etc/network/interfaces.d/openvpn-${br_device}.conf":
      ensure  => present,
      content => template('openvpn/openvpn-network.config.erb'),
      require => Package['openvpn'],
      notify  => Service['openvpn'],
    }
  }
}
