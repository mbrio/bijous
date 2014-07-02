'use strict';

var path = require('path');
var util = require('util');
var async = require('async');
var EventEmitter = require('events').EventEmitter;
var Klect = require('klect');

util.inherits(Bijous, EventEmitter);

/**
 * @callback Bijous~moduleCallback
 * @desc The callback used when loading modules to tell {@linkcode Bijous} that the module has completed loading.
 * @param {object=} error - If an error occurs the callback will receive an error object
 * @param {*=} results - An object used to represent the module after loading
 */

/**
 * @callback Bijous~module
 * @desc A module to be loaded by {@linkcode Bijous}. Any modules must conform to this protocol. This callback must be
 * the sole export of the module's entry-point.
 * @param {Bijous} context - The {@linkcode Bijous} object that is loading the module
 * @param {Bijous~moduleCallback} done - The callback that alerts {@linkcode Bijous} the async task is complete.
 * @example
 * exports = module.exports = function (context, done) {
 *   done(null, null);
 * }
 */

/**
 * An asynchronous module loader. Searches out {@linkcode Bijous~module|modules} and loads them asynchronously.
 * @class
 * @param {object=} options
 * @param {string=} options.cwd - Override the current working directory
 * @param {object=} options.bundles - Override the [klect]{@link https://github.com/awnist/klect} bundles description
 * @property {string} cwd - The current working directory, used to find modules. Defaults to the directory the module's
 * parent resides in
 * @property {object} bundles - The [klect]{@link https://github.com/awnist/klect} bundles description, used to find
 * modules. Defaults to {@linkcode Bijous#defaultBundles}
 * @property {object} modules - An object containing keys that represent results returned by modules when the
 * {@linkcode Bijous#load} method is called. The keys correspond with the module's filename, not including the
 * extension. (e.g. modules/module1 would have a key module1 and modules/module2.js would have a key module2)
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
 * @callback Bijous~loadCallback
 * @desc Used as a callback override for the {@linkcode Bijous#load} method. If one is specified then error handling
 * becomes it's responsibility. When one is not specified and an error occurs then the error will be thrown.
 * @param {object=} error - If an error occurs the callback will receive an error object
 * @param {*=} results - An array of any objects returned as representations of modules
 */

/**
 * Requires all modules found for it's bundles or a supplied bundle name, and executes the async callback defined by the
 * module
 * @param {string=} bundle - The name of the bundle that should be used when loading modules
 * @param {Bijous~loadCallback=} callback - A callback method to use when all modules are loaded
 */
Bijous.prototype.load = function load(bundle, callback) {
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
 * Loads all modules found for it's bundles or a supplied bundle name
 * @param {string=} bundle - The name of the bundle that should be used when requiring modules
 * @returns {object} - An object containing keys corresponding with the module's filename, not including the extension.
 * (e.g. modules/module1 would have a key module1 and modules/module2.js would have a key module2)
 */
Bijous.prototype.require = function req(bundle) {
  var assets = this.list(bundle);
  var self = this;
  var modules = {};
  
  assets.files().map(function (file) {
    var extname = path.extname(file);
    var basename = path.basename(file, extname);

    modules[basename] = require(path.join(self.cwd, file));
  });

  return modules;
};

/**
 * The default bundles definition, confirms to [klect]{@link https://github.com/awnist/klect} bundles
 */
Bijous.defaultBundles = 'modules/*';

exports = module.exports = Bijous;