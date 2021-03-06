class puppet_validator (
  String                  $path     = '/var/www/puppet-validator',
  Optional[Array[String]] $versions = undef,
) {
  # let's make sure the dir exists before we try to fill it with content!
  dirtree { $path:
    ensure  => present,
    parents => true,
    before  => File[$path]
  }

  file { $path:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  file { '/var/log/puppet-validator':
    ensure => file,
    owner  => 'nobody',
    group  => 'nobody',
    mode   => '0644',
  }

  package { 'graphviz':
    ensure => present,
  }

  package { 'puppet-validator':
    ensure   => present,
    provider => gem,
  }

  exec { 'puppet-validator init':
    cwd     => $path,
    creates => "${path}/config.ru",
    path    => '/bin:/usr/bin/:/usr/local/bin',
    require => Package['puppet-validator'],
  }

  # The bindir is to avoid binary collisions with PE. This must be installed
  # prior to the validator gem, because otherwise it will be installed as a
  # dependency and hit the /usr/local/bin/puppet symlink
  if $versions {
    $_versions = $versions.sort.reverse.join(', ')
    $_packages = $versions.map |$version| {
      "puppet:${version}"
    }.join(' ')

    # if the puppet gem is ever installed or updated manually, this will likely break
    exec { "gem install ${_packages} --bindir /tmp --no-document":
      path     => '/usr/local/bin:/usr/bin:/bin:/opt/puppetlabs/bin',
      unless   => "[[ \"$(gem list ^puppet$ | tail -1)\" == \"puppet (${_versions})\" ]]",
      provider => shell,
      before   => Package['puppet-validator'],
    }
  }
  else {
    package { ['puppet', 'facter']:
      ensure          => present,
      provider        => gem,
      install_options => { '--bindir' => '/tmp' },
      before          => Package['puppet-validator'],
    }
  }

}
