# Bijous


[![Build Status](https://travis-ci.org/mbrio/bijous.svg?branch=master)](https://travis-ci.org/mbrio/bijous)

[![NPM Status](https://nodei.co/npm/bijous.png?downloads=true)](https://npmjs.org/package/bijous)

An asynchronous module loader for node.js.

## Installation

You can use this node module in your project by executing the following:

```Shell
npm install bijous
```

or by saving it to your *package.json* file:

```Shell
npm install --save bijous
```

## Testing

```Shell
npm install && npm test
```

## Modules

All modules must conform to the rules set forth by [node](http://nodejs.org/api/modules.html) with the caveat that the module **MUST** export a method that receives a `context` argument and `done` argument. The `context` is a reference to the `Bijous` instance loading the module; and `done` is the callback used when the module has completed loading. The first argument to `done` is an error object and should only be supplied when an error has occurred; the second argument is an object that can be later references by the `Bijous` instance property `modules` which collects the results for each of the modules loaded. The `modules` property references the module loaded by it's filename, if we take the following code as an example and assume the code resides in a file called *modules/server/index.js*:

```JavaScript
var express = require('express');

exports = module.exports = function (context, done) {
  var app = express();

  done(null, {
      app: app,
      express: express
    });
};
```

Then the results from the server module could be accessed via:

```JavaScript
var app = bijous.modules.server.app;
app.use(middleware());
```

## Usage

The following code will load all modules within the `modules` folder.

```JavaScript
var Bijous = require('bijous');
var bijous = new Bijous();
bijous.load();
```

## License

ICS &copy; 2014 Michael Diolosa &lt;<michael.diolosa@gmail.com>&gt;