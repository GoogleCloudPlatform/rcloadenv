## rcloadenv

`rcloadenv` is a tool for loading configuration from the [Runtime Config
API](https://cloud.google.com/deployment-manager/runtime-configurator/).

## Installation

The language-specific implementations all load configurations from the Runtime
Config API. Choose the one that best fits your development environment.

### Go package

    go get -u github.com/GoogleCloudPlatform/rcloadenv

### Python package

    pip install rcloadenv

### Node.js package

Using `npm`:

    npm install -g @google-cloud/rcloadenv

Using `yarn`:

    yarn global add @google-cloud/rcloadenv

### Ruby package

Install the gem:

    gem install rcloadenv

Or include "rcloadenv" in your application's Gemfile.

## Usage

First, create a configuration using the [Google Cloud
SDK](https://cloud.google.com/sdk/).

    gcloud beta runtime-config configs create my-config

Then set the variables you wish to load. Variable names will be transformed
from lowercase to uppercase, separated by underscores.

    gcloud beta runtime-config configs variables set \
        my-variable-name my-value \
        --is-text --config-name my-config

To specify the project, set the `GOOGLE_CLOUD_PROJECT` environment variable.

    export GOOGLE_CLOUD_PROJECT=my-project-id

Use the `rcloadenv` command to launch your process.

    rcloadenv my-config -- bash -c 'echo $MY_VARIABLE_NAME'

## Disclaimer

This is not an official Google product, experimental or otherwise.

## Contributing changes

* See [CONTRIBUTING.md](CONTRIBUTING.md)

## Licensing

* See [LICENSE](LICENSE)

