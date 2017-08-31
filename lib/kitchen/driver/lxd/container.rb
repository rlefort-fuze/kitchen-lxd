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
#		http://www.apache.org/licenses/LICENSE-2.0
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
					@name = opts[:name]
					@image = opts[:image]
					@remote = opts[:remote]
					@binary = opts[:binary]
					update_state
				end

				def init
					return if created?
					download_image unless image_exists?
					run_command "#@binary init #@image #@name"
					update_state
				end

				def attach_network( network )
					return if device_attached? network
					run_command "#@binary network attach #{network} #@name"
					update_state
				end

				def start
					return if running?
					run_command "#@binary start #@name"
					update_state
				end

				def prepare_ssh
					run_command "#@binary exec #@name mkdir -- -p /root/.ssh"
					run_command "#@binary file push ~/.ssh/id_rsa.pub #@name/root/.ssh/authorized_keys"
					run_command "#@binary exec #@name chown -- root:root /root/.ssh/authorized_keys"
				end

				def destroy
					return unless created?
					run_command "#@binary delete #@name --force"
					update_state
				end

				def wait_for_ipv4
					info 'Wait for network to become ready.'
					9.times do
						update_state
						s = @state[:state].nil? ? @state[:State] : @state[:state]
						inet = s[:network][:eth0][:addresses].detect do |i|
							i[:family] == 'inet'
						end
						return inet[:address] if inet
						sleep 1 unless defined?( Minitest )
					end
					nil
				end

				def verify_dependencies
					version = run_command( "#@binary --version" ).strip
					if Gem::Version.new( version ) < Gem::Version.new( MIN_LXD_VERSION )
						raise UserError, "Detected old version of Lxd (#{version}), please upgrade to version "\
							"#{MIN_LXD_VERSION} or higher."
					end
				end

				def download_image
					run_command "#@binary image copy --copy-aliases #@remote:#@image local:"
				end

				private

				def image_exists?
					run_command "#@binary image show #@image"
				rescue ShellCommandFailed
					false
				end

				def update_state
					@state = JSON.parse(
						run_command( "#@binary list #@name --format json"), symbolize_names: true
					).first
				end

				def running?
					@state[:status] == 'Running'
				end

				def created?
					!@state.nil?
				end

				def device_attached?( network )
					@state[:devices] and @state[:devices][network.to_sym]
				end
			end
		end
	end
end
