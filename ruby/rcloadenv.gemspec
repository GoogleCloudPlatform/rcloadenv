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

lib = File.expand_path "../lib", __FILE__
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib
require 'rcloadenv/version'

::Gem::Specification.new do |spec|
  spec.name = "rcloadenv"
  spec.version = ::RCLoadEnv::VERSION
  spec.authors = ["Daniel Azuma"]
  spec.email = ["dazuma@gmail.com"]

  spec.summary = "Load Google Runtime Config data into environment variables"
  spec.description = "rcloadenv is a tool for loading configuration from the" \
    " Google Runtime Config API into environment variables. The rcloadenv" \
    " ruby gem is a ruby implementation of the tool that may be installed as" \
    " a ruby gem or included in a ruby Gemfile."
  spec.license = "Apache 2.0"
  spec.homepage = "https://github.com/GoogleCloudPlatform/rcloadenv"

  spec.files = ::Dir.glob("lib/**/*.rb") + ::Dir.glob("*.md") +
    [".yardopts", "bin/rcloadenv"]
  spec.required_ruby_version = ">= 2.0.0"
  spec.require_paths = ["lib"]

  spec.bindir = "bin"
  spec.executables = ["rcloadenv"]

  spec.add_dependency "google-api-client", "~> 0.13"
  spec.add_dependency "google-cloud-core", "~> 1.0"
  spec.add_dependency "google-cloud-env", "~> 1.0"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "rake", "~> 11.0"
  spec.add_development_dependency "rdoc", "~> 4.2"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "dotenv", "~> 2.2"
end
