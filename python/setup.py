#!/usr/bin/env python

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

import io
from os import path
from setuptools import setup, find_packages

# Get the long description from the README file
with io.open('README.rst', encoding='utf-8') as f:
    long_description = f.read()

setup(
    name='rcloadenv',
    version='0.1.0',
    description='Load environment variables from Google Cloud RuntimeConfig.',
    long_description=long_description,

    # The project's main homepage.
    url='https://github.com/GoogleCloudPlatform/rcloadenv',
    author='Tim Swast, Google Inc.',
    author_email='swast@google.com',
    license='Apache 2.0',

    # See https://pypi.python.org/pypi?%3Aaction=list_classifiers
    classifiers=[
        'Development Status :: 3 - Alpha',
        'Intended Audience :: Developers',
        'Topic :: System :: Installation/Setup',
        'License :: OSI Approved :: Apache Software License',
        'Operating System :: POSIX :: Linux',
        'Operating System :: MacOS :: MacOS X',
        'Programming Language :: Unix Shell',
    ],
    keywords='runtime configuration environment shell linux unix',

    install_requires=[
        'requests[security]>=2.13.0, <3.0.0dev',
        'google-auth>=0.10.0, <2.0.0dev',
    ],
    packages=find_packages(exclude=('tests*',)),
    entry_points={
        'console_scripts': [
            'rcloadenv=rcloadenv:main',
        ],
    },
)

