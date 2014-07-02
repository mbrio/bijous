'use strict';

var path = require('path');
var util = require('util');
var async = require('async');
var EventEmitter = require('events').EventEmitter;
var Klect = require('klect');

util.inherits(Bijous, EventEmitter);

/**
 * An asynchronous module loader
 * @class
 * @param {object=} options
 * @param {string=} options.cwd - Override the current working directory
 * @param {object=} options.bundles - Override the [klect]{@link https://github.com/awnist/klect} bundles description
 * @property {string} cwd - The current working directory, used to find modules. Defaults to the directory the module's parent resides in
 * @property {object} bundles - The [klect]{@link https://github.com/awnist/klect} bundles description, used to find modules. Defaults to {@linkcode Bijous#defaultBundles}
 * @property {object} modules - Container for results returned by modules when the {@linkcode Bijous#require} method is called
 */
function Bijous(options) {
  options = options || {};
  EventEmitter.call(this);

  var mod = module.parent;

  this.cwd = options.cwd || path.dirname(mod.filename);
  this.bundles = options.bundles || Bijous.defaultBundles;
  this.modules = {};
}

/**
 * Retrieves all modules found for it's bundles or a supplied bundle name
 * @param {string=} bundle - The name of the bundle that should be used when retrieving modules
 * @returns {object[]} - An array of [klect]{@link https://github.com/awnist/klect} assets
 */
Bijous.prototype.list = function list(bundle) {
  var klect = new Klect({ cwd: this.cwd });
  var assets = klect.gather(this.bundles);

  if (bundle) { return assets.bundles(bundle); }
  else { return assets; }
};

/**
 * @callback Bijous~requireCallback
 * @desc Used as a callback override for the {@linkcode Bijous#require} method. If one is specified then error handling
 * becomes it's responsibility. When one is not specified and an error occurs then the error will be thrown.
 * @param {object=} error - If an error occurs the callback will receive an error object
 * @param {*=} results - An array of any objects returned as representations of modules
 */

/**
 * Loads all modules found for it's bundles or a supplied bundle name
 * @param {string=} bundle - The name of the bundle that should be used when loading modules
 * @param {Bijous~requireCallback=} callback - A callback method to use when all modules are loaded
 */
Bijous.prototype.require = function load(bundle, callback) {
  if ('function' === typeof bundle) {
    callback = bundle;
    bundle = null;
  }

  var assets = this.list(bundle);
  var self = this;
  
  var fns = assets.files().map(function (file) {
    var extname = path.extname(file);
    var basename = path.basename(file, extname);

    return function loadAsset(done) {
      var cb = function (error, results) {
        if (results) { self.modules[basename] = results; }

        self.emit('loaded', basename, results);
        done(error, results);
      };

      require(path.join(self.cwd, file)).call(null, self, cb);
    };
  });

  async.series(fns, function (error, results) {
    if (callback) { callback(error, results); }
    else if (error) { throw error; }

    self.emit('done', self);
  });
};

/**
 * The default bundles definition, confirms to [klect]{@link https://github.com/awnist/klect} bundles
 */
Bijous.defaultBundles = 'modules/*';

exports = module.exports = Bijous;