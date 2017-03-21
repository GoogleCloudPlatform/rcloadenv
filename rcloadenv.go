// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// rcloadenv reads environment variables from the Google Cloud RuntimeConfig API.
//
// It outputs environment variables as separate lines (e.g. export
// VARIABLE_NAME=value) so that the output can be sourced to set the variables
// in a shell.
//
// If an environment variable is already set, it does not override it.
// The config name is set via the environment variable GOOGLE_RUNTIME_CONFIG_NAME
// If not set, the command exits without outputting.
//
// See
// https://cloud.google.com/deployment-manager/runtime-configurator/create-and-delete-runtimeconfig-resources
// for how to create a config and set variable values with the Cloud SDK.
package main

import (
	"encoding/base64"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"syscall"

	"golang.org/x/net/context"
	"golang.org/x/oauth2/google"
	runtimeconfig "google.golang.org/api/runtimeconfig/v1beta1"
)

func usage() {
	fmt.Fprintf(os.Stderr, "Usage: %s [config_name] -- command [args to command]\n\n", os.Args[0])
	fmt.Fprintln(os.Stderr, "This command populates the environment (if config_name is set)")
	fmt.Fprintln(os.Stderr, "and executes the specified command")
}

// validateArgs verifies number of arguments and location of --.
func validateArgs() bool {
	if len(os.Args) < 3 {
		return false
	}
	if os.Args[2] == "--" && len(os.Args) < 4 {
		return false
	}
	if os.Args[1] != "--" && os.Args[2] != "--" {
		return false
	}
	return true
}

func main() {
	if !validateArgs() {
		usage()
		os.Exit(1)
	}

	loadEnv := true
	cmdIndex := 3
	configName := os.Args[1]
	if configName == "--" {
		log.Println("Not loading from RuntimeConfig API because config name not specified")
		// Note that rcloadenv is intended to be used in a Docker container CMD like:
		//     CMD rcloadenv $configName -- python /app/myapp.py
		// Don't exit. Since this command is meant to supplement any runtime,
		// It's totally okay not to define a runtime config.
		loadEnv = false
		cmdIndex = 2
	}
	projectName := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectName == "" {
		projectName = os.Getenv("GCLOUD_PROJECT")
	}
	if projectName == "" {
		log.Println("Not loading from RuntimeConfig API because GOOGLE_CLOUD_PROJECT/GCLOUD_PROJECT not set")
		// Don't exit. Even though it's expected that one or both of
		// these environment variables will be set in App Engine, it's possible
		// a developer will not want to set these when running locally.
		loadEnv = false
	}

	cmd := os.Args[cmdIndex]
	binary, err := exec.LookPath(cmd)
	if err != nil {
		log.Fatalf("Failed to find command %s: %v", cmd, err)
	}
	env := os.Environ()
	if loadEnv {
		var err error
		env, err = loadEnviron(env, projectName, configName)
		if err != nil {
			log.Fatalf("Failed to load env: %v", err)
		}
	}
	if err := syscall.Exec(binary, os.Args[cmdIndex:], env); err != nil {
		log.Printf("%q %v\n", binary, os.Args[cmdIndex:])
		log.Fatalf("Failed to run process.")
	}
}

// loadEnviron loads environment variables from runtimeconfig and appends them to env.
func loadEnviron(
	env []string,
	projectName, configName string) ([]string, error) {
	ctx := context.Background()
	client, err := google.DefaultClient(ctx, runtimeconfig.CloudruntimeconfigScope)
	if err != nil {
		return nil, fmt.Errorf("could not create client: %v", err)
	}

	service, err := runtimeconfig.New(client)
	if err != nil {
		return nil, fmt.Errorf("could not create service: %v", err)
	}

	values, err := listVariables(ctx, service, projectName, configName)
	if err != nil {
		return nil, fmt.Errorf("could not fetch config: %v", err)
	}

	return appendEnviron(env, values), nil
}

// listVariables returns all variables from a config with name configName.
func listVariables(
	ctx context.Context,
	service *runtimeconfig.Service,
	projectName, configName string) (map[string]string, error) {
	parent := fmt.Sprintf("projects/%s/configs/%s", projectName, configName)
	vals := make(map[string]string)
	call := service.Projects.Configs.Variables.List(parent).ReturnValues(true)
	err := call.Pages(ctx, func(res *runtimeconfig.ListVariablesResponse) error {
		for _, v := range res.Variables {
			// Save text value.
			if v.Text != "" {
				vals[v.Name] = v.Text
				continue
			}
			// Save binary value.
			if vb, err := base64.StdEncoding.DecodeString(v.Value); err != nil {
				return fmt.Errorf("could not decode variable %s, %v: %v", v.Name, v.Value, err)
			} else {
				vals[v.Name] = string(vb[:])
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}

	return vals, nil
}

// appendEnviron adds variables to the os.Environ() environment.
//
// Transforms keys from "some-key" to "SOME_KEY". Doesn't overwrite variables
// already in the environment.
func appendEnviron(env []string, vars map[string]string) []string {
	for k, v := range vars {
		kparts := strings.Split(k, "/")
		envk := strings.Replace(kparts[len(kparts)-1], "-", "_", -1)
		envk = strings.ToUpper(envk)
		// Don't overwrite variables that are already there.
		if _, present := os.LookupEnv(envk); !present {
			env = append(env, fmt.Sprintf("%s=%s", envk, v))
		}
	}
	return env
}
