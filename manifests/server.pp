define openvpn::server (
    $ca_key_country,
    $ca_key_province,
    $ca_key_city,
    $ca_key_org,
    $ca_key_email,
    $ca_name,
    $remote,
    $device   = 'tap',
    $device_id = undef,
    $br_device = 'br2',
    $server_ip = ::ipaddress_eth1,
    $port = '1194',
    $netmask = '255.255.0.0',
    $pool_start = undef,
    $pool_end = undef,
    $user = 'nobody',
    $group = 'nogroup',
    $max_clients = '200',
    $push_dns_ip = undef,
    $push_route = [],
  ){


  $ca_path = "/etc/openvpn/ca/${ca_name}/easy-rsa"

  unless defined(Openvpn::Ca[$ca_name]) {
    openvpn::ca { $ca_name:
      key_country  => $ca_key_country,
      key_province => $ca_key_province,
      key_city     => $ca_key_city,
      key_org      => $ca_key_org,
      key_email    => $ca_key_email,
      remote       => $remote,
      device       => $device,
      device_id    => $device_id,
    }
  }
  file { "/etc/openvpn/openvpn-${name}.conf":
    ensure  => present,
    content => template('openvpn/openvpn_server.conf.erb'),
    require => Package['openvpn'],
    notify  => Service['openvpn'],
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
