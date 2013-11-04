node 'attacker' {
  package {[
    'libxml2-dev',
    'libxslt1-dev',
    'libcurl4-openssl-dev',
    'libsqlite3-dev',
    'libyaml-dev',
    'zlib1g-dev',
    'vim-nox',
    'curl',
    'ack-grep',
    'lynx',
    'libxslt-dev',
    'python2.7-dev',
    'python-nltk',
    'python-pip',
    'libcurl4-gnutls-dev',
    'libopenssl-ruby',
  ]:
    ensure => installed,
  }

  include stdlib
  include bundler
  include locales
  include gcc
  include git

  class { 'apt':
    always_apt_update => true,
    #stage             => setup,
  }

  class { 'ntp':
    autoupdate => true,
  }

  class { 'ruby':
    ruby_package     => 'ruby1.9.1-full',
    rubygems_package => 'rubygems1.9.1',
    gems_version     => 'latest',
  }

  class { 'motd': }

  class { 'timezone':
    timezone => 'UTC',
  }

  package {[
    'skipfish',
    'nmap',
    'nikto',
    'sslscan',
  ]:
    ensure => installed,
  }

  vcsrepo { '/opt/wpscan':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/wpscanteam/wpscan.git',
    require  => Class['git'],
  }

  bundler::install { '/opt/wpscan': 
    require => Vcsrepo['/opt/wpscan'],
  }

  vcsrepo { '/opt/w3af':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/andresriancho/w3af.git',
    require  => Class['git'],
  }

  vcsrepo { '/opt/garmr':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/mozilla/Garmr.git',
    require  => Class['git'],
  }

  exec { 'install garmr dependencies':
    command => 'python setup.py install',
    cwd     => '/opt/garmr',
    creates => '/opt/garmr/build',
    path    => '/usr/bin',
    require => [
      Vcsrepo['/opt/garmr'],
      Package['python2.7-dev'],
    ],
  }

  vcsrepo { '/opt/sqlmap':
    ensure   => present,
    provider => git,
    source   => 'https://github.com/sqlmapproject/sqlmap.git',
    require  => Class['git'],
  }

  vcsrepo { '/opt/sslyze':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/iSECPartners/sslyze.git',
    require  => Class['git'],
  }

  vcsrepo { '/opt/wpscanner':
    ensure   => present,
    provider => git,
    source   => 'git://github.com/metachris/wpscanner.git',
    require  => Class['git'],
  }

  file { '/opt/src':
    ensure => directory,
  }

  file { '/opt/tlssled':
    ensure => directory,
  }

  wget::fetch { 'download TLSSLed':
    source      => 'http://www.taddong.com/tools/TLSSLed_v1.3.sh',
    destination => '/opt/tlssled/TLSSLed.sh',
    require     => File['/opt/tlssled'],
    before      => File['/opt/tlssled/TLSSLed.sh'],
  }

  file { '/opt/tlssled/TLSSLed.sh':
    ensure  => present,
    mode    => '0755',
  }

  wget::fetch { 'download owasp zap':
    source      => 'https://zaproxy.googlecode.com/files/ZAP_2.2.0_Linux.tar.gz',
    destination => '/opt/src/zap.tar.gz',
    require     => File['/opt/src'],
    before      => Exec['untar and move owasp zap'],
  }

  exec { 'untar and move owasp zap':
    command  => '/bin/tar -xvf zap.tar.gz; mv ZAP* /opt/zap',
    cwd      => '/opt/src',
    creates  => '/opt/zap',
  }

  wget::fetch { 'download slowhttptest':
    source      => 'https://slowhttptest.googlecode.com/files/slowhttptest-1.5.tar.gz',
    destination => '/opt/src/slowhttptest-1.5.tar.gz',
    require     => File['/opt/src'],
    before      => Exec['untar slowhttptest'],
  }

  exec { 'untar slowhttptest':
    command  => '/bin/tar -xzvf slowhttptest-1.5.tar.gz;',
    cwd      => '/opt/src',
    creates  => '/opt/src/slowhttptest-1.5',
    before   => Exec['build slowhttptest'],
  }

  exec { 'build slowhttptest':
    command => 'bash configure; make; make install',
    path    => ['/usr/bin', '/bin'],
    cwd     => '/opt/src/slowhttptest-1.5',
    require => Class['gcc'],
  }

  package {[
    'arachni',
    'gauntlt',
  ]:
    ensure   => installed,
    provider => gem,
  }

  package {[
    'requests',
    'PyGithub',
    'GitPython',
    'pybloomfiltermmap',
    'esmre',
    'nltk',
    'pdfminer',
    'futures',
    'pyOpenSSL',
    'lxml',
    'scapy-real',
    'guess-language',
    'cluster',
    'msgpack-python',
    'python-ntlm',
  ]:
    ensure   => installed,
    provider => pip,
    require  => [
      Package['python2.7-dev'],
      Package['python-pip'],
      Package['python-nltk'],
    ],
  }

  exec { 'install phply':
    command => 'pip install -e git+git://github.com/ramen/phply.git#egg=phply',
    path    => '/usr/bin',
    creates => '/usr/local/lib/python2.7/dist-packages/phply.egg-link',
    cwd     => '/opt/src',
    require => [
      Class['git'],
      File['/opt/src'],
      Package['python-pip'],
    ],
  }

  apt::ppa { 'ppa:xkill/securitytools':}

  package {[
    'sqlibf',
    'dirb',
  ]:
    ensure  => installed,
    require => Apt::Ppa['ppa:xkill/securitytools'],
  }


  host { 'victim':
    ensure => present,
    ip     => '192.168.50.10',
  }

}

node 'target' {
  include wackopicko
  include stdlib
  include motd

  class { 'apt':
    always_apt_update => true,
    stage             => setup,
  }

  host { 'attacker':
    ensure => present,
    ip     => '192.168.50.20',
  }
}
