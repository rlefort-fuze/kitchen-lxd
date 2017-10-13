# -*- encoding: utf-8 -*-
#
# Author:: Juri Timošin (<draco.ater@gmail.com>)
#
# Copyright (C) 2017, Juri Timošin
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
require 'json'

module Kitchen
	module Driver
		class Lxd < Kitchen::Driver::Base
			class Container
				include ShellOut
				include Logging

				attr_reader :logger
				attr_reader :state

				def initialize( logger, opts )
					@logger = logger
					@name = opts[:container]
					@image = opts[:image]
					@remote = opts[:remote]
					@binary = opts[:binary]
				end

				def init
					return if created?
					download_image unless image_exists?
					run_command "#@binary init #@image #@name"
				end

				def attach_network( network )
					return if device_attached? network
					run_command "#@binary network attach #{network} #@name"
				end

				def start
					return if running?
					run_command "#@binary start #@name"
				end

				def destroy
					return unless created?
					run_command "#@binary delete #@name --force"
				end

				def wait_until_ready
					info 'Wait for network to become ready.'
					9.times do
						s = fetch_state[:state].nil? ? @state[:State] : @state[:state]
						inet = s[:network][:eth0][:addresses].detect do |i|
							i[:family] == 'inet'
						end
						return inet[:address] if inet
						sleep 1 unless defined?( Minitest )
					end
					nil
				end

				def download_image
					run_command "#@binary image copy --copy-aliases #@remote:#@image local:"
				end

				def execute( command )
					return if command.nil?
					run_command "#@binary exec #@name -- #{command}"
				end

				def login_command
					LoginCommand.new( "#@binary exec #@name -- bash", {} )
				end

				def upload( locals, remote )
					locals.each do |local|
						run_command "#@binary file push -rp #{local} #@name/#{remote}"
					end
				end

				def fix_chef_install( platform )
					case platform
					when /ubuntu/, /debian/
						execute "apt install -y wget"
					when /rhel/, /centos/
						execute 'yum install -y sudo wget'
					end
				end

				def fix_hostnamectl_bug
					logger.info "Replace /usr/bin/hostnamectl with /usr/bin/true, because of bug in Ubuntu. (https://bugs.launchpad.net/ubuntu/+source/apparmor/+bug/1575779)"
					execute 'rm /usr/bin/hostnamectl'
					execute 'ln -s /usr/bin/true /usr/bin/hostnamectl'
				end

				private

				def image_exists?
					!JSON.parse(
						run_command( "#@binary image list #@image --format json" ), symbolize_names: true
					).empty?
				end

				def fetch_state
					@state = JSON.parse(
						run_command( "#@binary list #@name --format json" ), symbolize_names: true
					).first
				end

				def running?
					fetch_state[:status] == 'Running'
				end

				def created?
					!fetch_state.nil?
				end

				def device_attached?( network )
					fetch_state[:devices] and @state[:devices][network.to_sym]
				end
			end
		end
	end
end
