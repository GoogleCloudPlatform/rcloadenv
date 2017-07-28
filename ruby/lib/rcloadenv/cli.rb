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

require "optparse"

module RCLoadEnv

  ##
  # Implementation of the rcloadenv command line.
  #
  class CLI

    ##
    # Create a command line handler.
    #
    # @param [Array<String>] args Command-line arguments
    #
    def initialize args
      @project = nil
      @exclude = []
      @include = []
      @override = false
      @debug = false

      @parser = OptionParser.new do |opts|
        opts.banner = "Usage: rcloadenv [options] <config-name> -- <command>"
        opts.on "-p name", "--project=name", "--projectId=name",
                "Project to read runtime config from" do |p|
          @project = p
        end
        opts.on "-E key1,key2,key3", "--except=key1,key2,key3",
                "Runtime-config variables to exclude, comma delimited" do |v|
          @exclude += v.split ","
        end
        opts.on "-O key1,key2,key3", "--only=key1,key2,key3",
                "Runtime-config variables to include, comma delimited" do |v|
          @include += v.split ","
        end
        opts.on "-o", "--override",
                "Cause config to override existing environment variables" do
          @override = true
        end
        opts.on "-d", "--debug", "Enable debug output" do
          @debug = true
        end
        opts.on_tail "--version", "Show the version and exit" do
          puts RCLoadEnv::VERSION
          exit
        end
        opts.on_tail "-?", "--help", "Show the help text and exit" do
          puts @parser.help
          exit
        end
      end

      separator_index = args.index "--"
      @command_list = separator_index ? args[(separator_index+1)..-1] : []

      args = args[0..separator_index] if separator_index
      begin
        remaining_args = @parser.parse args
      rescue OptionParser::ParseError => ex
        usage_error ex.message
      end
      @config_name = remaining_args.shift
      unless @config_name
        usage_error "You must provide a config name."
      end
      unless remaining_args.empty?
        usage_error "Extra arguments found: #{remaining_args.inspect}"
      end

      if @command_list.empty?
        usage_error "You must provide a command delimited by `--`."
      end
    end

    ##
    # Run the command line handler. This method either never returns or throws
    # an exception.
    #
    def run
      loader = RCLoadEnv::Loader.new @config_name,
          exclude: @exclude, include: @include, override: @override,
          project: @project, debug: @debug
      loader.modify_env ENV
      exec(*@command_list)
    end

    ## @private
    def usage_error msg
      STDERR.puts "rcloadenv: #{msg}"
      STDERR.puts @parser.help
      exit 1
    end
  end
end
