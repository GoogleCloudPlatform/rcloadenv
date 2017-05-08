<img src="https://avatars2.githubusercontent.com/u/2810941?v=3&s=96" alt="Google Inc. logo" title="Google" align="right" height="96" width="96"/>

# rcloadenv for Node.js

## CLI

### Installation

Using `npm`:

    npm install -g @google-cloud/rcloadenv

Using `yarn`:

    yarn global add @google-cloud/rcloadenv

### Usage

    rcloadenv <configName> -- <args...>

Examples:

    rcloadenv my-prod-config -- node app.js
    rcloadenv my-dev-config -- node app.js --debug

## API

### Installation

Using `npm`:

    npm install @google-cloud/rcloadenv

Using `yarn`:

    yarn add @google-cloud/rcloadenv

### Usage

Just load raw variables from the Runtime Config service:

```js
const rcloadenv = require('@google-cloud/rcloadenv');

rcloadenv.getVariables('my-config')
  .then((variables) => {
    variables.forEach((variable) => {
      console.log(variable);
    });
  })
  .catch((err) => {
    console.error('ERROR:', err);
  });
```

Load the variables and apply them to the current environment:
```js
const rcloadenv = require('@google-cloud/rcloadenv');

rcloadenv.getAndApply('my-config')
  .then(() => {
    console.log(process.env.MY_VAR);
  })
  .catch((err) => {
    console.error('ERROR:', err);
  });
```

Load the variables and mix them into a provided object:
```js
const rcloadenv = require('@google-cloud/rcloadenv');

const newEnv = Object.assign({}, process.env);

rcloadenv.getAndApply('my-config', newEnv)
  .then((env) => {
    console.log(env.MY_VAR);
  })
  .catch((err) => {
    console.error('ERROR:', err);
  });
```
