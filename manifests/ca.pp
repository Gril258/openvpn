define openvpn::ca (
    $key_country,
    $key_province,
    $key_city,
    $key_org,
    $key_email,
    $device,
    $device_id,
    $remote,
    $key_size = '2048',
    $ca_expire = '3650',
    $key_expire = '3650',
    $key_cn = $name,
    $key_name = $name,
    $key_ou = $name,
    $pkcs11_module_path = 'dummy',
    $pkcs11_pin = 'dummy'
) {
  exec { "copy-easy-rsa-${name}":
    command => "/bin/cp -ra /usr/share/easy-rsa /etc/openvpn/ca/${name}/easy-rsa",
    creates => "/etc/openvpn/ca/${name}/easy-rsa",
    require => [ Package['easy-rsa'], File["/etc/openvpn/ca/${name}"] ];
  }
  file { "/etc/openvpn/ca/${name}":
    ensure  => directory,
    mode    => '0755',
    require => Class['openvpn'],
  }
  file  { "/etc/openvpn/ca/${name}/easy-rsa/vars":
    ensure  => present,
    mode    => '0755',
    content => template('openvpn/ca-vars.erb'),
    require => File["/etc/openvpn/ca/${name}/easy-rsa/openssl-1.0.0.cnf"],
  }
  file { "/etc/openvpn/ca/${name}/easy-rsa/openssl-1.0.0.cnf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openvpn/openssl.cnf',
    require => Exec["copy-easy-rsa-${name}"],
  }

  Exec {
      path => [ '/sbin', '/bin', '/usr/sbin', '/usr/bin' ],
  }
  exec { "generate-ca-${name}":
    command  => '. ./vars && ./pkitool --initca',
    cwd      => "/etc/openvpn/ca/${name}/easy-rsa",
    creates  => "/etc/openvpn/ca/${name}/easy-rsa/keys/ca.crt",
    provider => 'shell',
    require  => Exec["generate-dh-${name}"];
  }
  exec { "generate-cert-${name}":
    command  => ". ./vars && ./pkitool --server server-${name}",
    cwd      => "/etc/openvpn/ca/${name}/easy-rsa",
    creates  => "/etc/openvpn/ca/${name}/easy-rsa/keys/server-${name}.crt",
    provider => 'shell',
    require  => Exec["generate-ca-${name}"]
  }
  exec { "generate-clr-${name}":
    command  => ". ./vars && ./pkitool test-revoke-${name} && ./revoke-full test-revoke-${name} && chmod 755 /etc/openvpn/ca/${name}/easy-rsa/keys/ && chmod 755 /etc/openvpn/ca/${name}/easy-rsa/keys/crl.pem",
    cwd      => "/etc/openvpn/ca/${name}/easy-rsa",
    returns  => '2',
    creates  => "/etc/openvpn/ca/${name}/easy-rsa/keys/crl.pem",
    provider => 'shell',
    require  => Exec["generate-cert-${name}"]
  }
  exec { "generate-dh-${name}":
    command  => '. ./vars && ./clean-all && ./build-dh',
    cwd      => "/etc/openvpn/ca/${name}/easy-rsa",
    creates  => "/etc/openvpn/ca/${name}/easy-rsa/keys/dh${key_size}.pem",
    provider => 'shell',
    timeout  => '0',
    require  => File["/etc/openvpn/ca/${name}/easy-rsa/vars"],
  }

  file { "/etc/openvpn/ca/${name}/easy-rsa/keys":
    ensure  => directory,
    mode    => '0755',
    require => Exec["generate-dh-${name}"],
  }

  file { "/etc/openvpn/ca/${name}/easy-rsa/keys/rars":
    ensure  => directory,
    require => File["/etc/openvpn/ca/${name}/easy-rsa/keys"],
  }

  file { "/etc/openvpn/ca/${name}/easy-rsa/keys/example":
    ensure  => directory,
    require => File["/etc/openvpn/ca/${name}/easy-rsa/keys"],
  }

  file { "/etc/openvpn/ca/${name}/easy-rsa/keys/example/openvpn-${name}.conf.ovpn":
    ensure  => file,
    mode    => '0755',
    content => template('openvpn/openvpn_example_client_tap.conf.ovpn.erb'),
    require => File["/etc/openvpn/ca/${name}/easy-rsa/keys/example"],
  }
}
