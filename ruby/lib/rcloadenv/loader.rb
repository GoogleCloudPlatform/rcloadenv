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

require "rcloadenv/api_client"
require "google/cloud/env"

module RCLoadEnv

  ##
  # A class that loads environment variables from a RuntimeConfig resource.
  #
  class Loader

    ##
    # Error thrown when inputs are malformed.
    #
    class UsageError < StandardError
    end

    ##
    # Create a loader. Alwaus uses application default credentials.
    #
    # @param [String] config_name Name of the runtime config resource
    # @param [String,nil] project Optional name of the cloud project. If not
    #     set, attempts to infer one from the environment.
    #
    def initialize config_name,
                   exclude: nil, include: nil, override: false,
                   project: nil, debug: false
      @config_name = config_name.to_s
      @project = (project || default_project).to_s
      @exclude = exclude
      @include = include
      @override = override
      @debug = debug
    end

    ## @return [String] The Runtime Config resource name
    attr_reader :config_name
    ## @return [String] The cloud project
    attr_reader :project

    ##
    # Modify the given environment with the configuration. The given hash
    # is modified in place. If no hash is provided, a new one is created
    # and returned.
    #
    # @param [Hash<String,String>] env The environment to modify.
    # @return the environment.
    #
    def modify_env env={}
      raw_variables.each do |k, v|
        if !@exclude.empty? && @exclude.include?(k) ||
           !@include.empty? && !@include.include?(k)
          debug "Skipping config variable #{k}"
        else
          debug "Found config variable #{k}"
          key = k.split("/").last.upcase.gsub("-", "_")
          if !env.include?(key)
            debug "Setting envvar: #{key}"
            env[key] = v
          elsif @override
            debug "Overriding envvar: #{key}"
            env[key] = v
          else
            debug "Envvar already set: #{key}"
          end
        end
      end
      env
    end

    ##
    # Returns the has of variables retrieved from the runtime config.
    # Variable names have the parent (project and config name) stripped.
    # Values are all converted to strings.
    #
    # @return [Hash<String,String>] the variables.
    #
    def raw_variables
      @raw_variables ||= load_raw_variables
    end

    ## @private
    def service
      @service ||= create_service
    end

    ## @private
    def service= mock
      @service = mock
    end

    ## @private
    def load_raw_variables
      if project.empty?
        raise UsageError, "Project name must be provided."
      end
      if config_name.empty?
        raise UsageError, "Config name must be provided."
      end
      parent_path = "projects/#{project}/configs/#{config_name}"
      debug "Loading #{config_name} from project #{project}"
      response = service.list_project_config_variables \
        parent_path, return_values: true
      raw_variables = {}
      (response.to_h[:variables] || []).each do |var_info|
        key = var_info[:name].sub "#{parent_path}/variables/", ""
        raw_variables[key] = var_info[:text] || var_info[:value]
      end
      raw_variables
    end

    ## @private
    def default_project
      ENV["GOOGLE_CLOUD_PROJECT"] ||
        ENV["GCLOUD_PROJECT"] ||
        Google::Cloud.env.project_id ||
        `gcloud config get-value project 2>/dev/null`.strip
    end

    ## @private
    def create_service
      s = Google::Apis::RuntimeconfigV1beta1::CloudRuntimeConfigService.new
      s.client_options.application_name = "rcloadenv-ruby"
      s.client_options.application_version = RCLoadEnv::VERSION
      s.request_options.retries = 3
      s.request_options.header ||= {}
      s.request_options.header["x-goog-api-client"] = \
        "gl-ruby/#{RUBY_VERSION} rcloadenv/#{RCLoadEnv::VERSION}"
      s.authorization = RCLoadEnv::Credentials.default.client
      s
    end

    ## @private
    def debug str
      STDERR.puts "RCLOADENV DEBUG: #{str}" if @debug
    end
  end

end
