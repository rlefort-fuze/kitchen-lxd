# Kitchen::Lxd

[![Build Status](https://travis-ci.org/DracoAter/kitchen-lxd.svg?branch=master)](https://travis-ci.org/DracoAter/kitchen-lxd)
[![Gem Version](https://badge.fury.io/rb/kitchen-lxd.svg)](https://badge.fury.io/rb/kitchen-lxd)

- [Requirements](#requirements)
	- [Lxd](#lxd)
- [Installation and Setup](#installation-and-setup)
- [Configuration](#configuration)
	- [Driver](#driver)
	- [Transport](#transport)
- [Development](#development)
- [Authors](#authors)
- [License](#license)

A Test Kitchen Driver (with Transport) for Lxd.

## Requirements

### Lxd

Lxd version of 2.3 (the one where "lxc network" commands were introduced) or higher is required
for this driver which means that a native package must be installed on the system running Test
Kitchen.

You do not have to prepare any container image specifically, like downloading it or installing ssh
server. The driver will download container image automatically from the provided remote server,
if it's not available locally. Also you can use `lxd` transport instead of default `ssh`. Which
means files will be uploaded to container using `lxc file push` command.

## Installation and Setup

Install using command line:

```bash
gem install kitchen-lxd
```

## Configuration

Example config file may look like this:

```yaml
---
driver:
  name: lxd
  binary: lxc # this is default
  remote: images # default
  network: lxdbr0 # default
  fix_chef_install: false # default
  fix_hostnamectl_bug: true # default

transport:
  name: lxd
```

Default values can be omitted, so the minimal config file looks like this:

```yaml
---
driver:
  name: lxd

transport:
  name: lxd
```

### Driver

Available options:

Name | Description | Type | Default
-----|-------------|------|--------
binary | Path to lxc executable. | String | `lxc`
remote | Remote LXD server to download image from, if it does not exist locally. | String | `images`
network | Network bridge to attach to container. | String | `lxdbr0`
wait_until_ready | Wait for the network to come up. | Boolean | `true`
fix_chef_install | Apply fix, to make available installation of Chef Omnibus package. | Boolean | `false`
fix_hostnamectl_bug | Apply workaround to Ubuntu [hostnamectl bug](https://bugs.launchpad.net/ubuntu/+source/apparmor/+bug/1575779) in LXD. | Boolean | `true`

## Development

- Source hosted at [GitHub][repo]
- Report issues/questions/feature requests on [GitHub Issues][issues]

Pull requests are very welcome! Make sure your patches are well tested.
Ideally create a topic branch for every separate change you make. For
example:

1. Fork the repo
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Authors

Created and maintained by [Juri Timošin][author].

## License

Apache 2.0 (see [LICENSE][license])

[author]:           https://github.com/DracoAter
[issues]:           https://github.com/DracoAter/kitchen-lxd/issues
[license]:          https://github.com/DracoAter/kitchen-lxd/blob/master/LICENSE
[repo]:             https://github.com/DracoAter/kitchen-lxd
