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
    # @param [String] invocation The rcloadenv binary invoked.
    # @param [Array<String>] args Command-line arguments
    #
    def initialize invocation, args
      @invocation = invocation
      @args = args
      @project = nil
      @exclude = []
      @include = []
      @override = false
      @debug = false
      @disable_bundler = false
      parser = OptionParser.new do |opts|
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
        opts.on "-B", "--disable-bundler", "Disable auto bundle exec" do
          @disable_bundler = true
        end
        opts.on "-?", "--help", "Show the help text and exit" do
          puts parser.help
          exit
        end
      end
      @command_list = parser.parse args
      @config_name = @command_list.shift
      unless @config_name && @command_list.size > 0
        STDERR.puts "rcloadenv: config name and command are both required."
        STDERR.puts parser.help
        exit 1
      end
    end

    ##
    # Run the command line handler. This will rewrap the invocation in
    # `bundle exec` if needed. This method either never returns or throws
    # an exception.
    #
    def run
      execute if @disable_bundler
      execute unless ENV["BUNDLE_GEMFILE"].to_s.empty?
      execute unless bundler_exists?
      execute unless gemfile_exists?
      if @debug
        puts "Rerunning rcloadenv under bundle exec. Pass -B to disable this."
      end
      exec "bundle", "exec", @invocation, "-B", *@args
    end

    ##
    # Determine whether bundler appears to be present
    # @private
    #
    def bundler_exists?
      `bundle version`
      $?.exitstatus == 0
    end

    ##
    # Determine whether there is a Gemfile
    # @private
    #
    def gemfile_exists?
      File.readable? "Gemfile"
    end

    ##
    # Load the runtime config and execute the command. Never returns.
    # @private
    #
    def execute
      loader = RCLoadEnv::Loader.new @config_name,
          exclude: @exclude, include: @include, override: @override,
          project: @project, debug: @debug
      loader.modify_env ENV
      exec *@command_list
    end
  end
end
