# frozen_string_literal: true

require 'rake/clean'
require 'rake/testtask'
require 'rubygems/package_task'
require 'rdoc/rdoc'

require_relative 'lib/kitchen/driver/version'

CLOBBER << 'html'

RDoc::Task.new do |t|
	t.main = 'README.md'
	t.rdoc_files.include('README.md', 'lib/**/*.rb')
end

CLOBBER << 'doc'

Gem::PackageTask.new(Gem::Specification.load('kitchen-lxd.gemspec')){}

desc 'Install this gem locally.'
task :install, [:user_install] => :gem do |_t, args|
	args.with_defaults(user_install: Process.uid != 0)
	Gem::Installer.new("pkg/kitchen-lxd-#{Kitchen::Driver::Lxd::VERSION}.gem",
		user_install: args.user_install).install
end

begin
	require 'rubocop/rake_task'
	RuboCop::RakeTask.new(:rubocop) do |t|
		t.options = ['--display-cop-names']
	end
	task default: :rubocop
	task 'test:unit': :rubocop
	task 'test:integration': :rubocop
rescue LoadError
	puts "Rubocop not found. It's rake tasks are disabled."
end

namespace :test do
	CLOBBER << 'test/coverage'
	CLOBBER << 'test/unit.log'
	CLOBBER << 'test/integration.log'

	%w[unit integration].each do |name|
		Rake::TestTask.new name do |t|
			t.description = "Run #{name} tests and generate coverage reports."
			t.verbose = true
			t.warning = true
			t.test_files = FileList["test/#{name}/*_test.rb"]
		end
	end

	desc 'Run all tests and generate coverage reports.'
	task all: %i[unit integration]
end
task default: 'test:unit'

namespace :ci do
	CLOBBER << 'test/reports'

	%w[all unit integration].each do |name|
		desc "Run #{name} tests and generate report for CI."
		task name do
			ENV['CI_REPORTS'] = 'test/reports/'
			require 'ci/reporter/rake/minitest'
			Rake::Task['ci:setup:minitest'].invoke
			Rake::Task["test:#{name}"].invoke
		end
	end
end
