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

require "rcloadenv/api_client"
require "google/cloud/credentials"

module RCLoadEnv
  ##
  # @private Represents the OAuth 2.0 signing logic for Runtime Config.
  #
  class Credentials < Google::Cloud::Credentials
    SCOPE = [Google::Apis::RuntimeconfigV1beta1::AUTH_CLOUDRUNTIMECONFIG]
    PATH_ENV_VARS = %w(GOOGLE_CLOUD_KEYFILE GCLOUD_KEYFILE)
    JSON_ENV_VARS = %w(GOOGLE_CLOUD_KEYFILE_JSON GCLOUD_KEYFILE_JSON)
  end
end
