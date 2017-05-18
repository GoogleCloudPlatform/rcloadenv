# Spring Cloud Config Client for Google Cloud Runtime Configurator API

## Prepare
1. Install the [Google Cloud SDK](https://cloud.google.com/sdk/). You
  can do so with the following command:
```
  curl https://sdk.cloud.google.com | bash
```
1. Create, enable billing on a project on the [Google Cloud Console](https://console.cloud.google.com).
1. Enable the [Runtime Config API](https://console.cloud.google.com/flows/enableapi?apiid=runtimeconfig.googleapis.com)
1. Set the `GOOGLE_CLOUD_PROJECT` or `GCLOUD_PROJECT` environment variable.
```
    export GOOGLE_CLOUD_PROJECT=my-project-id
```
1. (Local testing only)
Using the `Runtime Configurator` in your application requires that `GOOGLE_APPLICATION_CREDENTIALS` environment variable be set to point to
an authorized service account credentials file. More instructions on creating the credentials file [here](https://developers.google.com/identity/protocols/application-default-credentials#howtheywork).

## Build

```
   cd rcloadenv
   mvn clean install
```

## Testing

1. Create a configuration using the [Google Cloud
SDK](https://cloud.google.com/sdk/). The configuration name
should be in the format `application.id`_`profile`, for example : `myapp_prod`

    gcloud beta runtime-config configs create myapp_prod

Then set the variables you wish to load. Variable names will be transformed
from lowercase to uppercase, separated by underscores.
```
  gcloud beta runtime-config configs variables set \
    queue_size 25 \
    --config-name myapp_prod
  gcloud beta runtime-config configs variables set \
    feature_x_enabled true \
    --config-name myapp_prod
```

1. In your Spring Boot application directory (see the sample application [here](sample-spring-boot-app)),
add the following line to `src/main/resources/META-INF/spring.factories` :
```
  org.springframework.cloud.bootstrap.BootstrapConfiguration=com.google.cloud.rcloadenv.RuntimeConfigPropertySourceLocator
```

1. Add the following dependency to your `pom.xml`:
```
  <dependency>
    <groupId>com.google.cloud</groupId>
    <artifactId>rcloadenv</artifactId>
    <version>0.0.1-alpha-SNAPSHOT</version>
  </dependency>
```

1. Set an `application.id` and profile(default = `default`) in your `src/main/resources/application.properties`:
```
    application.id=myapp
    spring.profiles.active=prod
```

1. Add Spring style configuration variables, see [SampleConfig.java](sample-spring-boot-app/src/main/java/com/example/SampleConfig.java)

```
  @Value("${queue_size}")
  private int queueSize;

  @Value("${feature_x_enabled}")
  private boolean isFeatureXEnabled;
```

1. (Optional Step) [Spring Boot Actuator](http://cloud.spring.io/spring-cloud-static/docs/1.0.x/spring-cloud.html#_endpoints) provides support to have configuration parameters be reloadable with the POST `/refresh` endpoint.
Add the following dependency to your `pom.xml`:
```
  <dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
  </dependency>
```
Then, add `@RefreshScope` to your configuration class to have parameters be reloadable at runtime.
Update a property with gcloud and then call the `/refresh` endpoint:
```
   gcloud beta runtime-config configs variables set \
     queue_size 200 \
     --config-name myapp_prod
   curl -XPOST http://myapp.host.com/refresh
```

## References
* [Externalized configuration in Spring](https://cloud.spring.io/spring-cloud-config/)
* [Customizing bootstrap property sources](http://projects.spring.io/spring-cloud/spring-cloud.html#customizing-bootstrap-property-sources)
