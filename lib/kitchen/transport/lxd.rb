
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
require 'forwardable'

module Kitchen
	module Transport
		# Transport for Lxd driver for Kitchen.
		#
		# @author Juri Timoshin <draco.ater@gmail.com>
		class Lxd < Base
			kitchen_transport_api_version 2

			default_config :container do |transport|
				transport.instance.driver.container
			end

            def finalize_config!(instance)
              super.tap do
                if defined?(Kitchen::Verifier::Inspec) && instance.verifier.is_a?(Kitchen::Verifier::Inspec)
                  instance.verifier.send(:define_singleton_method, :runner_options_for_lxd) do |config_data|
                    runner_options_for_exec(config_data)
                  end
                end
              end
            end

			def connection(state, &block)
				@connection = Connection.new(config.to_hash.merge(state), &block)
			end

			class Connection < Base::Connection
				extend Forwardable

				def initialize(opts)
					@container = opts[:container]
					super(opts)
				end

				def_delegators :@container, :execute, :login_command, :upload, :wait_until_ready
			end
		end
	end
end
