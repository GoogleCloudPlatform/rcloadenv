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

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.cloud.bootstrap.config.PropertySourceLocator;
import org.springframework.core.env.Environment;
import org.springframework.core.env.MapPropertySource;
import org.springframework.core.env.PropertySource;

import java.io.IOException;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Custom property source locator for Google Cloud Runtime Configurator. */
public class RuntimeConfigPropertySourceLocator implements PropertySourceLocator {

  private static final Logger logger =
      LoggerFactory.getLogger(RuntimeConfigPropertySourceLocator.class);

  @Override
  public PropertySource<?> locate(Environment environment) {
    String appName = environment.getRequiredProperty("application.name");
    String projectId = getProjectId();
    List<String> profiles = Arrays.asList(environment.getActiveProfiles());
    Map<String, Object> config = new HashMap<>();
    for (String profile : profiles) {
      String propertySourceName = appName + "_" + profile;
      try {
        Map<String, Object> source =
            RuntimeConfigLoaderUtil.loadConfig(projectId, propertySourceName);
        for (Map.Entry<String, Object> entry : source.entrySet()) {
          config.putIfAbsent(entry.getKey(), entry.getValue());
        }
      } catch (IOException e) {
        logger.error("Error loading configuration for {}/{}: {} ", projectId, propertySourceName
        , e.getMessage());
      }
    }
    return new MapPropertySource("com.google.cloud.rcloadenv", config);
  }

  String getProjectId() {
    String projectId = System.getenv("GOOGLE_CLOUD_PROJECT");
    if (projectId == null) {
      projectId = System.getenv("GCLOUD_PROJECT");
    }
    if (projectId == null) {
      throw new IllegalArgumentException(
          "Project id not available : GOOGLE_CLOUD_PROJECT or GCLOUD_PROJECT not set");
    }
    return projectId;
  }
}
