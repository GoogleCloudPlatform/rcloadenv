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

# As of google-api-client 0.13.1 (July 2017) there isn't a client for
# RuntimeConfig V1beta1, but there might be in the future. So first we attempt
# to load a client from google-api-client, but if it doesn't exist, we use
# a vendored client we generated on 2017-07-19.
begin
  require "google/apis/runtimeconfig_v1beta1"
rescue LoadError
  require "rcloadenv/google/apis/runtimeconfig_v1beta1"
end
