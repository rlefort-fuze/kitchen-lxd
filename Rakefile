require 'rake/clean'
require 'rake/testtask'
require 'rubygems/package_task'

require_relative 'lib/kitchen/driver/version'

CLEAN << 'doc'
CLEAN << 'test/coverage'
CLEAN << 'test/reports'

Gem::PackageTask.new( Gem::Specification.load( 'kitchen-lxd.gemspec' ) ) do end

desc 'Install this gem locally.'
task :install, [:user_install] => :gem do |t, args|
	args.with_defaults( user_install: Process.uid != 0  )
	Gem::Installer.new( "pkg/kitchen-lxd-#{Kitchen::Driver::Lxd::VERSION}.gem",
		user_install: args.user_install ).install
end

namespace :test do
	%w{unit integration}.each do |name|
		Rake::TestTask.new name do |t|
			t.description = "Run #{name} tests and generate coverage reports."
			t.verbose = true
			t.warning = true
			t.test_files = FileList["test/#{name}/*_test.rb"]
		end
	end

	desc 'Run all tests and generate coverage reports.'
	task :all => [:unit, :integration]
end

namespace :ci do
	%w{all unit integration}.each do |name|
		desc "Run #{name} tests and generate report for CI."
		task name do
			ENV['CI_REPORTS'] = 'test/reports/'
			require 'ci/reporter/rake/minitest'
			Rake::Task['ci:setup:minitest'].invoke
			Rake::Task["test:#{name}"].invoke
		end
	end
end
