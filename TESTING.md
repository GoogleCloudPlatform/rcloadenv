# Testing

The tests in this repository are system tests and run against live services,
therefore, it takes a bit of configuration to run all of the tests locally.

Before you can run tests locally you must have:

* The [Google Cloud SDK](https://cloud.google.com/sdk/) installed. You
  can do so with the following command:

      curl https://sdk.cloud.google.com | bash

## Preparing a project for testing

Tests require you to have an active, billing-enabled project on the
[Google Cloud Console](https://console.cloud.google.com).

### Creating resources

Some resources need to be created in a project ahead of time before testing. We
have a script that can create everything needed:

    gcloud config set project [YOUR-PROJECT-ID]
    ./scripts/prepare-testing-project.sh

Replace `[YOUR-PROJECT-ID]` with your Google Cloud Platform project ID.

### Load the rcloadenv binary to your PATH

The rcloadenv binary needs to be on your PATH to test locally.

#### Python

Activate a virtual environment.

    virtualenv env
    source env/bin/activate

Install the rcloadenv Python package in editable mode.

    pip install -e ./python

#### Node.js

1.  Change directory into the Node.js folder:

        cd nodejs

1.  Install dependencies:

        npm install

1.  Temporarily add the Node.js rcloadenv binary to your path:

        export PATH=$PATH:/path/to/rcloadenv/nodejs/bin/rcloadenv

#### Ruby

Ruby 2.0 or later is required. Make sure a recent version of bundler is
available. If not, run:

    gem install bundler

Make sure the gem dependencies are installed:

    bundle install --gemfile=ruby/Gemfile

Temporarily add the Ruby rcloadenv binary to your path:

    export PATH=/path/to/rcloadenv/ruby/bin:$PATH

### Run the test

    ./testing/run-test.sh

