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

    bundle exec rcloadenv my-config -- bin/rails s

If `rcloadenv` is run on Google Cloud Platform hosting (such as Google Compute
Engine, Container Engine, or App Engine), then it infers the project name and
credentials from the hosting environment.

If you are not running on GCP, you may set the project using the `--project`
switch, or by setting the `GOOGLE_CLOUD_PROJECT` environment variable. For
example:

    bundle exec rcloadenv --project=my-project my-config -- bin/rails s

Run `rcloadenv --help` for more information on flags you can set.
When not running on GCP, credentials are obtained from
[Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials)
so you can the `GOOGLE_APPLICATION_CREDENTIALS` environment variable or
configure `gcloud auth`.

## Example: Loading the Rails SECRET_KEY_BASE in Google App Engine

This gem is commonly used to provide sensitive information such as API keys or
database passwords to a Ruby application deployed to Google Cloud Platform,
without exposing them to configuration files checked into source control.

For example, Rails applications require the environment variable
`SECRET_KEY_BASE` to be set in the production environment. When deploying a
Rails application to Google App Engine, you could set this environment
variable in the "app.yaml" configuration file, but that is not recommended
because the "app.yaml" file is commonly checked into source control. Instead,
you can set the `SECRET_KEY_BASE` value securely in the Runtime Config
service, and use `rcloadenv` to load it into the Rails app. Here's how.

1.  We will assume that you have a [Ruby on Rails](http://rubyonrails.org/)
    application, you have set up a
    [Google App Engine](https://cloud.google.com/appengine/) project to deploy
    it to, you have the [Google Cloud SDK](https://cloud.google.com/sdk/)
    installed, and you have logged in with gcloud and set your project name in
    the gcloud configuration.

    See https://cloud.google.com/ruby for more information on deploying a
    Ruby application to Google App Engine.

2.  Enable the Runtime Config API for your project using the Google Cloud
    Console (https://console.cloud.google.com/). To do so, navigate to
    https://console.cloud.google.com/apis/api/runtimeconfig.googleapis.com/overview
    choose the correct project and click "Enable".

3.  Use the gcloud command line to create a Runtime Configuration:

        gcloud beta runtime-config configs create my-config

    Choose a name for your configuration and replace `my-config` with that
    name. Any keys you set in this configuration will be loaded as environment
    variables in your application.

    Because you will be storing sensitive information in this configuration
    resource, you may consider restricting access to it. See
    https://cloud.google.com/deployment-manager/runtime-configurator/access-control
    for more information. If you do so, make sure any service accounts that
    run `rcloadenv` retain access to the resource. That includes the App Engine
    service account (which runs your application in App Engine) and the
    Cloud Build service account (which performs build steps such as asset
    precompilation for your application).

4.  Create a secret key

        bundle exec rake secret

    This will generate a random key and print it to the console.

5.  Use the gcloud command line to set `SECRET_KEY_BASE` in your configuration.

        gcloud beta runtime-config configs variables set \
          SECRET_KEY_BASE 12345678 --config-name=my-config

    Replace `my-config` with the name of your configuration, and `12345678`
    with the secret key that you generated above.

6.  Add the `rcloadenv` gem to your Gemfile, and run `bundle install` to update
    your bundle.

7.  Now set the entrypoint in your "app.yaml" configuration file to load the
    Runtime Configuration into environment variables using `rcloadenv`. For
    example, if entrypoint would normally be:

        bundle exec bin/rails s

    Then change it to:

        bundle exec rcloadenv my-config -- bin/rails s

    Replace `my-config` with the name of your configuration.

    (If you previously set SECRET_KEY_BASE in the env_variables section of your
    app.yaml, remove it. You no longer need it!)

    Now when you deploy and run your application, it should load the
    SECRET_KEY_BASE value from your Runtime Configuration.

8.  If you have set any custom build steps for your application that require
    this configuration, make sure you update them too. For example, you might
    use the following to build rails assets:

        bundle exec rcloadenv my-config -- rake assets:precompile

You may set additional environment variables, such as database names and
passwords, in this config as well, whether or not they are sensitive. It's a
useful way to manage your application's configuration independent of its
source code and config files.

## More info

More info can be found in the general cross-language rcloadenv README at
https://github.com/GoogleCloudPlatform/rcloadenv
