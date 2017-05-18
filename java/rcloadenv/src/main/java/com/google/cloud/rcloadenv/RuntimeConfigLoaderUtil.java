/*
 * Copyright 2017 Google Inc. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.google.cloud.rcloadenv;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.api.client.http.GenericUrl;
import com.google.api.client.http.HttpRequest;
import com.google.api.client.http.HttpRequestFactory;
import com.google.api.client.http.HttpResponse;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.auth.http.HttpCredentialsAdapter;
import com.google.auth.oauth2.GoogleCredentials;
import com.google.auth.oauth2.ServiceAccountCredentials;

import java.io.IOException;
import java.util.Base64;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

class RuntimeConfigLoaderUtil {

  private static final String RUNTIMECONFIG_API_ROOT =
      "https://runtimeconfig.googleapis.com/v1beta1/";
  private static final String RUNTIMECONFIG_SCOPE =
      "https://www.googleapis.com/auth/cloudruntimeconfig";
  private static final String VARIABLES_PATH =
      "%sprojects/%s/configs/%s/variables?returnValues=true";

  private static final ObjectMapper mapper = new ObjectMapper();

  static Map<String, Object> loadConfig(String projectId, String appName) throws IOException {
    GoogleCredentials credentials =
        ServiceAccountCredentials.getApplicationDefault()
            .createScoped(Collections.singleton(RUNTIMECONFIG_SCOPE));
    String url = String.format(VARIABLES_PATH, RUNTIMECONFIG_API_ROOT, projectId, appName);
    HttpCredentialsAdapter adapter = new HttpCredentialsAdapter(credentials);
    NetHttpTransport httpTransport = new NetHttpTransport();
    HttpRequestFactory requestFactory = httpTransport.createRequestFactory();
    HttpRequest request = requestFactory.buildGetRequest(new GenericUrl(url));
    adapter.initialize(request);
    HttpResponse response = request.execute();
    return getConfigValues(response);
  }

  private static Map<String, Object> getConfigValues(HttpResponse response) throws IOException {
    String responseStr = response.parseAsString();
    Map<String, Object> config = new HashMap<>();
    Map<String, List<Variable>> map =
        mapper.readValue(responseStr, new TypeReference<Map<String, List<Variable>>>() {});
    for (Variable variable : map.get("variables")) {
      Object value = variable.getText();
      if (value == null && variable.getValue() != null) {
        value = new String(Base64.getDecoder().decode(variable.getValue()));
      }
      if (value != null) {
        String variableName = variable.getName();
        String[] variableNameSplit = variableName.split("/");
        if (variableNameSplit.length > 0) {
          String shortName = variableNameSplit[variableNameSplit.length - 1];
          config.put(shortName, value);
        }
      }
    }
    return config;
  }
}
