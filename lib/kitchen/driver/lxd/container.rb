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
				include Logging
				include ShellOut

				attr_reader :logger
				attr_reader :state

				def initialize( logger, opts )
					@logger = logger
					@name = opts[:container]
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
					run_command "#@binary network attach #{network} #@name" unless device_attached? network
					update_state
				end

				def start
					return if running?
					run_command "#@binary start #@name"
					update_state
				end

				def destroy
					return unless created?
					run_command "#@binary delete #@name --force"
					update_state
				end

				def wait_until_ready
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

				private

				def image_exists?
					!JSON.parse(
						run_command( "#@binary image list #@image --format json" ), symbolize_names: true
					).empty?
				end

				def update_state
					@state = JSON.parse(
						run_command( "#@binary list #@name --format json" ), symbolize_names: true
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
