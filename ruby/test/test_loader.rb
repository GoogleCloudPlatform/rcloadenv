# Copyright 2017 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
;

require "minitest/autorun"
require "rcloadenv"

module RCLoadEnv
  module Tests  # :nodoc:

    class TestLoader < ::Minitest::Test  # :nodoc:

      PROJECT = "my-project"
      CONFIG = "my-config"

      def setup_loader opts={}
        loader = Loader.new CONFIG, opts.merge(project: PROJECT)
        mock = Minitest::Mock.new
        mock.expect :list_project_config_variables,
          {
            variables: [
              {name: "var1", value: "binval"},
              {name: "var2", text: "txtval"},
              {name: "long/path/name", value: "value3"},
              {name: "Name-With-Dashes", value: "value4"}
            ]
          },
          ["projects/#{PROJECT}/configs/#{CONFIG}", {return_values: true}]
        loader.service = mock
        result = yield loader
        mock.verify
        result
      end

      def test_transforms
        setup_loader do |loader|
          expected_env = {
            "VAR1" => "binval",
            "VAR2" => "txtval",
            "NAME" => "value3",
            "NAME_WITH_DASHES" => "value4"
          }
          assert_equal expected_env, loader.modify_env
        end
      end

      def test_exclude
        setup_loader exclude: ["var1", "VAR2", "long/path/name"] do |loader|
          expected_env = {
            "VAR2" => "txtval",
            "NAME_WITH_DASHES" => "value4"
          }
          assert_equal expected_env, loader.modify_env
        end
      end

      def test_include
        setup_loader include: ["var1", "VAR2", "long/path/name"] do |loader|
          expected_env = {
            "VAR1" => "binval",
            "NAME" => "value3",
          }
          assert_equal expected_env, loader.modify_env
        end
      end

      def test_no_override
        setup_loader do |loader|
          env = {
            "VAR1" => "original"
          }
          expected_env = {
            "VAR1" => "original",
            "VAR2" => "txtval",
            "NAME" => "value3",
            "NAME_WITH_DASHES" => "value4"
          }
          assert_equal expected_env, loader.modify_env(env)
        end
      end

      def test_override
        setup_loader override: true do |loader|
          env = {
            "VAR1" => "original"
          }
          expected_env = {
            "VAR1" => "binval",
            "VAR2" => "txtval",
            "NAME" => "value3",
            "NAME_WITH_DASHES" => "value4"
          }
          assert_equal expected_env, loader.modify_env(env)
        end
      end

    end

  end
end
