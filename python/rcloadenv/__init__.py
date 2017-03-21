#!/usr/bin/env python

# Copyright 2017 Google Inc. All Rights Reserved.
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

"""Use the google runtime config library to fetch all configuration
variables for a particular config and launch a command with that configuration
set as environment variables.

    rcloadenv my-config -- my-command --args-for my-command
"""

import argparse
import base64
import logging
import os

import google.auth
import google.auth.transport.requests


_RUNTIMECONFIG_API_ROOT = 'https://runtimeconfig.googleapis.com/v1beta1/'
_RUNTIMECONFIG_SCOPE = 'https://www.googleapis.com/auth/cloudruntimeconfig'
_VARIABLES_PATH = '{root}projects/{project}/configs/{config_name}/variables'

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def _create_session():
    """Create a session authorized for the Runtime Config API.

    Uses Google application default credentials to authorize and find the
    default project name.

    See:
    https://developers.google.com/identity/protocols/application-default-credentials

    Returns:
        Tuple[google.auth.transport.requests.AuthorizedSession, str]: A tuple
            containing a Requests Session authorized with Google credentials and a
            project ID.
    """
    credentials, project = google.auth.default(scopes=[_RUNTIMECONFIG_SCOPE])
    session = google.auth.transport.requests.AuthorizedSession(credentials)
    return session, project


def _list_variables(session, project, config_name):
    """List all the variables and their values in a config.

    Args:
        session (google.auth.transport.requests.AuthorizedSession): A Requests
            Session which is authorized to connect to the Runtime Config API.
        project (str): The project ID for the Google Cloud project which
            contains the desired config.
        config (str): Name of the the config to list.

    Returns:
        Mapping[str, Any]: A dictionary of variables. Keys are the variable
            names, and values are the variable values.
    """
    uri = _VARIABLES_PATH.format(
        root=_RUNTIMECONFIG_API_ROOT, project=project, config_name=config_name)
    r = session.get(uri, params={'returnValues': True})
    r.raise_for_status()

    variables = {}

    for variable in r.json().get('variables', []):
        # The variable name has the whole path in it, so just get the last
        # part.
        variable_name = variable['name'].split('/')[-1]
        variable_value = None

        if variable.get('text') is not None:
            variable_value = variable['text']
        else:
            variable_value = base64.b64decode(variable['value']).decode('utf-8')

        variables[variable_name] = variable_value

    return variables


def _fetch(config_name):
    """Fetch the variables and values for the given config.

    The command is authorized using Google application default credentials, and
    it reads the config from the default project.

    Args:
        config (str): Name of the the config to fetch.

    Returns:
        Mapping[str, Any]: A dictionary of variables. Keys are the variable
            names, and values are the variable values.
    """
    session, project = _create_session()

    logger.info('Fetching runtime configuration {} from {}.'.format(
        config_name, project))

    variables = _list_variables(session, project, config_name)

    return variables


def _environ(variables):
    """Copy ``os.environ`` and populate it with additional variables.

    Transforms the key name from ``some-key`` to ``SOME_KEY``.  It will *not*
    replace keys already present in ``os.environ``. This means you can locally
    override whatever is in the runtime config.

    Args:
        variables (Mapping[str, Any]): A dictionary of variables. Keys are the
            variable names, and values are the variable values.

    Returns:
        Mapping[str, str]: A dictionary representing the copied environment,
            populated with new environment variables from ``variables``.
    """

    env = os.environ.copy()

    for name, value in variables.items():
        compliant_name = name.upper().replace('-', '_')
        env.setdefault(compliant_name, str(value))

    return env


def main():
    """Execute command specified in command_args with environment loaded from
    config_name in the RuntimeConfig API.
    """
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        'config_name',
        help='Config name for RuntimeConfig API')
    parser.add_argument('command', help='Command to execute.')
    parser.add_argument(
        'command_args',
        help='Arguments to pass to command.',
        nargs=argparse.REMAINDER)
    args = parser.parse_args()

    variables = _fetch(args.config_name)
    env = _environ(variables)
    os.execvpe(args.command, [args.command] + args.command_args, env)


if __name__ == '__main__':
    main()
