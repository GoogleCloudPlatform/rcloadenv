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

E_ASSERT_FAILED=99

# Assert that a variable value is not empty.
#
# Params:
#     $1: name of the variable to check
#     $2: expected value of the variable
assert_has_value ()
{
  var_name="$1"
  expected_value="$2"

  # Use indirect expansion to get the value of the variable with that name.
  # http://stackoverflow.com/a/16790646/101923
  if [ "${!var_name}" != "${expected_value}" ]
  then
    (>&2 echo "$var_name has value \"${!var_name}\", expected \"${expected_value}\"")
    return $E_ASSERT_FAILED
  fi
}

for i in {1..100} ; do
  assert_has_value TEXT_VAR_$i value-$i
  assert_has_value BINARY_VAR_$i value-$i
done

assert_has_value OVERRIDE_VAR value-not-from-runtime-config

if [ -z "${EMPTY_VAR+set}" ]; then
  (>&2 echo "EMPTY_VAR is unset, expected set to empty string")
  exit $E_ASSERT_FAILED
fi

