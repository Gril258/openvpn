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
  # create copy of easy rsa directory - this will create main certificate authority directory
  exec { "copy-easy-rsa-${name}":
    command => "/bin/cp -ra /usr/share/easy-rsa /etc/openvpn/ca/${name}/easy-rsa",
    creates => "/etc/openvpn/ca/${name}/easy-rsa",
    require => [ Package['easy-rsa'], File["/etc/openvpn/ca/${name}"] ];
  }
  # directory where are stored certificate authorities
  file { "/etc/openvpn/ca/${name}":
    ensure  => directory,
    mode    => '0755',
    require => Class['openvpn'],
  }
  # set variables for certificate authority configuration
  file  { "/etc/openvpn/ca/${name}/easy-rsa/vars":
    ensure  => present,
    mode    => '0755',
    content => template('openvpn/ca-vars.erb'),
    require => File["/etc/openvpn/ca/${name}/easy-rsa/openssl-1.0.0.cnf"],
  }
  # ssl configuration file TODO revision of security
  file { "/etc/openvpn/ca/${name}/easy-rsa/openssl-1.0.0.cnf":
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/openvpn/openssl.cnf',
    require => Exec["copy-easy-rsa-${name}"],
  }
  # set $PATH for exec
  Exec {
      path => [ '/sbin', '/bin', '/usr/sbin', '/usr/bin' ],
  }
  # initialize certificate authority
  exec { "generate-ca-${name}":
    command  => '. ./vars && ./pkitool --initca',
    cwd      => "/etc/openvpn/ca/${name}/easy-rsa",
    creates  => "/etc/openvpn/ca/${name}/easy-rsa/keys/ca.crt",
    provider => 'shell',
    require  => Exec["generate-dh-${name}"];
  }
  # generate main server certification file
  exec { "generate-cert-${name}":
    command  => ". ./vars && ./pkitool --server server-${name}",
    cwd      => "/etc/openvpn/ca/${name}/easy-rsa",
    creates  => "/etc/openvpn/ca/${name}/easy-rsa/keys/server-${name}.crt",
    provider => 'shell',
    require  => Exec["generate-ca-${name}"]
  }
  # create certificate revoke list needed for able to revoke clients
  exec { "generate-crl-${name}":
    command  => ". ./vars && ./pkitool test-revoke-${name} && ./revoke-full test-revoke-${name} && chmod 755 /etc/openvpn/ca/${name}/easy-rsa/keys/ && chmod 755 /etc/openvpn/ca/${name}/easy-rsa/keys/crl.pem",
    cwd      => "/etc/openvpn/ca/${name}/easy-rsa",
    returns  => '2',
    creates  => "/etc/openvpn/ca/${name}/easy-rsa/keys/crl.pem",
    provider => 'shell',
    require  => Exec["generate-cert-${name}"]
  }
  # diffle helmans cyphre generate
  exec { "generate-dh-${name}":
    command  => '. ./vars && ./clean-all && ./build-dh',
    cwd      => "/etc/openvpn/ca/${name}/easy-rsa",
    creates  => "/etc/openvpn/ca/${name}/easy-rsa/keys/dh${key_size}.pem",
    provider => 'shell',
    timeout  => '0',
    require  => File["/etc/openvpn/ca/${name}/easy-rsa/vars"],
  }
  # ca key directory
  file { "/etc/openvpn/ca/${name}/easy-rsa/keys":
    ensure  => directory,
    mode    => '0755',
    require => Exec["generate-dh-${name}"],
  }
  # where client rars are stored from mk-vpn-cert.sh
  file { "/etc/openvpn/ca/${name}/easy-rsa/keys/rars":
    ensure  => directory,
    require => File["/etc/openvpn/ca/${name}/easy-rsa/keys"],
  }
  # example certificate directory
  file { "/etc/openvpn/ca/${name}/easy-rsa/keys/example":
    ensure  => directory,
    require => File["/etc/openvpn/ca/${name}/easy-rsa/keys"],
  }
  # example config file for clients
  file { "/etc/openvpn/ca/${name}/easy-rsa/keys/example/openvpn-${name}.conf.ovpn":
    ensure  => file,
    mode    => '0755',
    content => template('openvpn/openvpn_example_client_tap.conf.ovpn.erb'),
    require => File["/etc/openvpn/ca/${name}/easy-rsa/keys/example"],
  }
}
