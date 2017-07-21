# Ruby implementation of rcloadenv

`rcloadenv` is a tool for loading configuration from the [Runtime Config
API](https://cloud.google.com/deployment-manager/runtime-configurator/).

This is a Ruby implementation that may be installed as a Rubygem.

## Usage

Install the gem using

    gem install rcloadenv

Alternately, include "rcloadenv" in your bundle.

You may then invoke the "rcloadenv" binary. You must pass the name of the
runtime config resource, and then the command to execute. For example:

    rcloadenv my-config -- bundle exec bin/rails s

## More info

See https://github.com/GoogleCloudPlatform/rcloadenv for more information.
