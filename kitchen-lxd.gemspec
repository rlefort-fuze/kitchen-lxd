# frozen_string_literal: true

require_relative 'lib/kitchen/driver/version'
require 'date'

Gem::Specification.new do |s|
	s.name = 'kitchen-lxd'
	s.version = Kitchen::Driver::Lxd::VERSION
	s.authors = ['Juri Timošin']
	s.email = ['draco.ater@gmail.com']
	s.summary = 'An Lxd driver for Test Kitchen.'
	s.description = 'Kitchen::Driver::Lxd - an Lxd driver (and transport) for Test Kitchen.'
	s.homepage = 'https://github.com/DracoAter/kitchen-lxd'
	s.license = 'Apache-2.0'
	s.date = Date.today

	s.files = Dir['CHANGELOG.md', 'LICENSE', 'README.md', 'lib/**/*']
	s.require_path = 'lib'

	s.required_ruby_version = '~> 2.3'

	s.add_dependency 'test-kitchen', '~> 2.00'

	s.add_development_dependency 'ci_reporter_minitest', '~> 1.0'
	s.add_development_dependency 'minitest', '~> 5.5'
	s.add_development_dependency 'rake', '~> 12.0'
	s.add_development_dependency 'simplecov', '~> 0.10'
end
