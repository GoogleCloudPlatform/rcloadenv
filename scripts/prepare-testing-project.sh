#!/bin/bash

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

set -e

GCLOUD_PROJECT=$(gcloud config list project --format="value(core.project)" 2>/dev/null)

echo "Configuring project $GCLOUD_PROJECT for system tests."

echo "Follow this link to enable APIs."
echo "https://console.cloud.google.com/flows/enableapi?project=${GCLOUD_PROJECT}&apiid=runtimeconfig.googleapis.com"
echo
# https://unix.stackexchange.com/a/293941/11193
read -r -p "After they are enabled, press enter to continue."

gcloud beta runtime-config configs create rcloadenv-test

for i in {1..100} ; do
  gcloud beta runtime-config \
    configs variables set \
    text-var-$i value-$i \
    --is-text --config-name rcloadenv-test
  gcloud beta runtime-config \
    configs variables set \
    binary-var-$i value-$i \
    --config-name rcloadenv-test
done

gcloud beta runtime-config \
  configs variables set \
  override-var this-value-shouldnt-appear \
  --is-text --config-name rcloadenv-test

gcloud beta runtime-config \
  configs variables set \
  empty-var "" \
  --is-text --config-name rcloadenv-test

