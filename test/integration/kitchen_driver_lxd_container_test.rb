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
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'test_helper'
require 'logger'
require 'resolv'

module Kitchen
	module Driver
		class Lxd
			module IntegrationTest
				class ContainerTest < Minitest::Test
					def setup
						@subj = Lxd::Container.new(::Logger.new(StringIO.new), container: 'kitchen-lxd-test',
							image: 'alpine/3.6', binary: 'lxc', remote: 'images')
					end

					def teardown
						@subj.destroy
					end

					def test_init_success
						assert_equal false, @subj.created?
						@subj.init
						assert_equal true, @subj.created?
					end

					def test_init_already_created
						assert_equal false, @subj.created?
						@subj.init
						assert_equal true, @subj.created?
						@subj.init
						assert_equal true, @subj.created?
					end

					def test_attach_network_success
						@subj.init
						assert_equal false, @subj.device_attached?('lxdbr0')
						assert_equal false, @subj.state[:devices].key?('lxdbr0')
						@subj.attach_network 'lxdbr0'
						assert_equal true, @subj.device_attached?('lxdbr0')
						assert_equal({ nictype: 'bridged', parent: 'lxdbr0', type: 'nic' },
							@subj.state[:devices][:lxdbr0])

						# further calls do not change state
						state = @subj.state
						@subj.attach_network 'lxdbr0'
						assert_equal state, @subj.fetch_state
					end

					def test_start_success
						@subj.init
						assert_equal false, @subj.running?
						@subj.start
						assert_equal true, @subj.running?

						# further calls do not change state
						assert_equal true, @subj.running?
						@subj.start
						assert_equal true, @subj.running?
					end

					def test_destroy_success
						@subj.init
						assert_equal true, @subj.created?
						@subj.destroy
						assert_equal false, @subj.created?

						# further calls do not change state
						assert_nil @subj.state
						@subj.destroy
						assert_nil @subj.fetch_state
					end

					def test_wait_until_ready_success
						@subj.init
						@subj.attach_network 'lxdbr0'
						@subj.start
						assert_match Resolv::IPv4::Regex, @subj.wait_until_ready
					end

					def test_wait_until_ready_fail
						@subj.init
						@subj.start
						assert_nil @subj.wait_until_ready
					end

					def test_execute
						@subj.init
						@subj.start
						assert_equal 'kitchen-lxd-test x86_64 Linux', @subj.execute('uname -nmo').strip
					end

					def test_login_command_exists_in_container
						@subj.init
						@subj.start
						assert_equal '/bin/sh', @subj.execute('which ' +
							@subj.login_command.command.split('--').last).strip
					end

					def test_upload
						@subj.init
						@subj.start
						assert_equal true, @subj.running?
						assert_equal '', @subj.upload([File.expand_path('.gitignore')], '/tmp')
						assert_equal IO.read('.gitignore'), @subj.execute('cat /tmp/.gitignore')
					end

					def test_download_image
						assert_equal '', `lxc image delete #{@subj.instance_variable_get(:@image)}`
						assert_equal '', `lxc image list #{@subj.instance_variable_get(:@image)} --format csv`
						@subj.init
						assert_equal "alpine/3.6 (3 more)\n",
							`lxc image list #{@subj.instance_variable_get(:@image)} --format csv -c l`
					end

					def test_install_chef
						@subj.init
						@subj.attach_network 'lxdbr0'
						@subj.start
					end
				end
			end
		end
	end
end
