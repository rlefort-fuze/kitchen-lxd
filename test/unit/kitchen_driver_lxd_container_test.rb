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
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'test_helper'
require 'logger'

module Kitchen
	module Driver
		class Lxd
			module UnitTest
				class ContainerTest < Minitest::Test
					def setup
						@subj = Lxd::Container.new( ::Logger.new( StringIO.new ), container: 'kitchen-lxd-test',
							image: 'alpine/3.6', binary: 'lxc', remote: 'images' )
					end

					def test_constructor
						assert_equal 'kitchen-lxd-test', @subj.instance_variable_get( :@name )
						assert_equal 'alpine/3.6', @subj.instance_variable_get( :@image )
						assert_equal 'lxc', @subj.instance_variable_get( :@binary )
						assert_equal 'images', @subj.instance_variable_get( :@remote )
					end

					def test_login_command
						assert_equal 'lxc exec kitchen-lxd-test -- sh', @subj.login_command.command
					end
				end
			end
		end
	end
end
