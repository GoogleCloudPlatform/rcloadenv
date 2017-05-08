/**
 * Copyright 2016, Google, Inc.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

'use strict';

const googleAuth = require('google-auto-auth');
const got = require('got');
const path = require('path');
const snakeCase = require('lodash.snakecase');

const PAGE_SIZE = 100;

function fetchPage (url, authToken, nextPageToken) {
  const query = {
    pageSize: PAGE_SIZE,
    returnValues: true
  };

  if (nextPageToken) {
    query.pageToken = nextPageToken;
  }

  return got.get(url, {
    headers: {
      'Authorization': `Bearer ${authToken}`
    },
    query,
    json: true
  }).then((response) => {
    const variables = response.body.variables || [];
    if (variables.length < PAGE_SIZE) {
      return variables;
    } else {
      return fetchPage(url, authToken, response.body.nextPageToken)
        .then((_variables) => variables.concat(_variables || []));
    }
  });
}

/**
 * Retrieves all variables in the given config.
 *
 * @param {string} configName
 * @param {object} [opts]
 * @returns {Promise}
 */
exports.getVariables = (configName, opts = {}) => {
  opts.projectId || (opts.projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT);
  opts.scopes || (opts.scopes = ['https://www.googleapis.com/auth/cloudruntimeconfig']);

  let requestUrl;

  return new Promise((resolve, reject) => {
    const auth = googleAuth(opts);
    auth.getToken((err, authToken) => {
      if (err) {
        reject(err);
        return;
      } else if (!auth.projectId) {
        reject(new Error('Could not determine project ID'));
        return;
      }

      requestUrl = `https://runtimeconfig.googleapis.com/v1beta1/projects/${auth.projectId}/configs/${configName}/variables`;
      resolve(authToken);
    });
  }).then((authToken) => fetchPage(requestUrl, authToken));
};

/**
 * Transforms the given array of raw variables into a simple key-value object.
 *
 * In: [{name:"...",value:"..."}, ...]
 * Out: { VAR1: "...", VAR2: "...", ... }
 *
 * @param {object[]} variables
 */
exports.transform = (variables) => {
  const env = {};

  variables.forEach((variable) => {
    let value;
    const name = path.parse(variable.name).base;

    if (variable.text) {
      value = variable.text;
    } else if (variable.value) {
      value = Buffer.from(variable.value, 'base64').toString();
    }

    env[snakeCase(name).toUpperCase()] = env[name] = value;
  });

  return env;
};

/**
 * Applies the provided raw variables to the given object.
 *
 * @param {object[]} variables
 * @param {object} [env]
 */
exports.apply = (variables, env = process.env) => {
  return Object.assign(env, exports.transform(variables));
};

/**
 * Retrieves all variables in the given config and mixes them into the given
 * object.
 *
 * @param {string} configName
 * @param {object} [env]
 * @param {object} [opts]
 * @returns {Promise}
 */
exports.getAndApply = (configName, env = process.env, opts = {}) => {
  return exports.getVariables(configName, opts)
    .then((variables) => exports.apply(variables, env));
};
