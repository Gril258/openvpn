class openvpn {
  # main openvpn package
  package { 'openvpn':
    ensure => 'latest',
  }
  # certificate authority utility
  package { 'easy-rsa':
    ensure => 'latest',
  }
  # utility for managing bridge devices
  package { 'bridge-utils':
    ensure => 'latest',
  }
  # rar
  package { 'rar':
    ensure => 'latest',
  }
  # configure main network file
  file { '/etc/network/interfaces':
    ensure  => present,
    mode    => '0644',
    content => template('openvpn/interfaces.erb'),
  }
  # create directory for certificate authority
  file { '/etc/openvpn/ca':
    ensure => 'directory',
  }
  # shell script for create vpn device and connect it to bridge
  file { '/etc/openvpn/vpn-up.sh':
    ensure  => present,
    mode    => '0755',
    source  => 'puppet:///modules/openvpn/vpn-up.sh',
    require => Package['openvpn'],
  }
  # undo what first done
  file { '/etc/openvpn/vpn-down.sh':
    ensure  => present,
    mode    => '0755',
    source  => 'puppet:///modules/openvpn/vpn-down.sh',
    require => Package['openvpn'],
  }
  # example ca directory
  file { '/etc/openvpn/ca/EasyRSA-2.2.2':
    ensure => directory,
  }
  # script for creating client certificates
  file { '/usr/local/sbin/mk-vpn-cert':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/openvpn/mk-vpn-cert.sh'
  }
  # openvpn service resource
  service { 'openvpn':
    ensure  => 'running',
    enable  => true,
    require => Package['openvpn'],
  }
  # openvpn systemd services files, original but updated for restart and restart always
  file { '/lib/systemd/system/openvpn@.service':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('openvpn/openvpn@.service.erb'),
    require => Package['openvpn'],
  }
}
