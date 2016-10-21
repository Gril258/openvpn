class openvpn {

  package { 'openvpn':
    ensure => 'latest',
  }

  package { 'easy-rsa':
    ensure => 'latest',
  }

  package { 'bridge-utils':
    ensure => 'latest',
  }

  package { 'rar':
    ensure => 'latest',
  }

  file { '/etc/network/interfaces':
    ensure  => present,
    mode    => '0644',
    content => template('openvpn_server/interfaces.erb'),
  }

  file { '/etc/openvpn/ca':
    ensure => 'directory',
  }

  file { '/etc/openvpn/vpn-up.sh':
    ensure  => present,
    mode    => '0755',
    source  => "puppet:///modules/openvpn/vpn-up.sh",
    require => Package['openvpn'],
  }
  file { '/etc/openvpn/vpn-down.sh':
    ensure  => present,
    mode    => '0755',
    source  => "puppet:///modules/openvpn/vpn-down.sh",
    require => Package['openvpn'],
  }


  file { '/etc/openvpn/ca/EasyRSA-2.2.2':
    ensure => directory,
  }

  file { '/usr/local/sbin/mk-vpn-cert':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => "puppet:///modules/openvpn/mk-vpn-cert.sh"
  }

  service { 'openvpn':
    ensure  => 'running',
    enable  => true,
    require => Package['openvpn'],
  }
}




