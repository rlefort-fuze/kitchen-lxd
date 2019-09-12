
# frozen_string_literal: true

#
# Author:: Juri Timoshin (<draco.ater@gmail.com>)
#
# Copyright (C) 2017, Juri Timoshin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'kitchen'
require 'tempfile'
require 'json'

module Kitchen
	module Driver
		class Lxd < Kitchen::Driver::Base
			class Container
				include ShellOut
				include Logging

				attr_reader :logger
				attr_reader :state

				def initialize(logger, opts)
					@logger = logger
					@name = opts[:container]
					@image = opts[:image]
					@remote = opts[:remote]
					@binary = opts[:binary]
					@fix_hostnamectl_bug = opts[:fix_hostnamectl_bug]
                    @lxd_remote = %x<echo -n $(#{@binary} remote get-default)>
				end

				def init(config={})
					return if created?
					download_image unless image_exists?
					config_args = config.map{|k, v| "-c #{k}='#{v}'" }.join(' ')
					run_command "#{@binary} init #{@lxd_remote}:#{@image} #{@name} #{config_args}"
				end

				def attach_network(network)
					return if device_attached? network
					run_command "#{@binary} network attach #{network} #{@name}"
				end

				def start
					return if running?
					run_command "#{@binary} start #{@name}"
				end

				def destroy
					return unless created?
					run_command "#{@binary} delete #{@name} --force"
				end

				def wait_until_ready
					info 'Wait for network to become ready.'
					9.times do
						s = fetch_state[:state].nil? ? @state[:State] : @state[:state]
						inet = s.dig(:network, :eth0, :addresses)&.detect do |i|
							i[:family] == 'inet'
						end
						return inet[:address] if inet
						sleep 1 unless defined?(Kitchen::Driver::UnitTest)
					end
					nil
				end

				def download_image
					run_command "#{@binary} image copy --copy-aliases #{@remote}:#{@image} #{@lxd_remote}:"
				end

				def execute(command)
					return if command.nil? or command.empty?
					fix_hostnamectl_bug if @fix_hostnamectl_bug
                    command_file = Tempfile.create do |f|
                      f.write(command)
                      f.rewind
                      run_command "#{@binary} file push -p --mode 777 #{f.path} #{@name}#{f.path}"
                      run_command "#{@binary} exec --user 0 #{@name} -- bash -s < #{f.path}"
                      run_command "#{@binary} exec --user 0 #{@name} -- rm -f #{f.path}"
                    end
				end

				def login_command
					LoginCommand.new("#{@binary} exec #{@name} -- $(#{@binary} exec #{@name} -- head -1 "\
						'/etc/passwd | cut -d: -f7)', {})
				end

				def upload(locals, remote)
					return if locals.nil? or locals.empty?
					run_command "#{@binary} file push -r #{locals.join(' ')} #{@name}#{remote}"
				end

				def fix_chef_install(platform)
					case platform
					when /ubuntu/, /debian/
						execute 'apt-get update'
						execute 'apt-get install -y wget'
					when /rhel/, /centos/
						execute 'yum install -y sudo wget'
					end
				end

				def fix_hostnamectl_bug
					logger.info 'Replace /usr/bin/hostnamectl with /usr/bin/true, because of bug in Ubuntu'\
						'. (https://bugs.launchpad.net/ubuntu/+source/apparmor/+bug/1575779)'
					run_command "#{@binary} exec #{@name} -- ln -fs /usr/bin/true /usr/bin/hostnamectl"
				end

    #				private

				def image_exists?
					!JSON.parse(
						run_command("#{@binary} image list #{@image} --format json"), symbolize_names: true
					).empty?
				end

				def fetch_state
					@state = JSON.parse(
						run_command("#{@binary} list #{@name} --format json"), symbolize_names: true
					).first
				end

				def running?
					fetch_state[:status] == 'Running'
				end

				def created?
					!fetch_state.nil?
				end

				def device_attached?(network)
					fetch_state.dig(:devices, network.to_sym) ? true : false
				end
			end
		end
	end
end
