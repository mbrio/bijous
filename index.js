'use strict';

var path = require('path');
var util = require('util');
var async = require('async');
var EventEmitter = require('events').EventEmitter;
var Klect = require('klect');

util.inherits(Bijous, EventEmitter);

/**
 * @callback Bijous~moduleDone
 * @desc The callback used to alert {@linkcode Bijous} that a module has completed loading.
 * @param {*=} error - If a breaking error occurs it should be passed as the first parameter
 * @param {*=} result - An object used to represent the module
 * @example
 * // We may assume this resides in a file modules/module1/index.js
 * exports = module.exports = function (context, done) {
 *   if (shouldFail) { return done(new Error('some error')); }
 *   done(null, {
 *     moduleData: 'some data'
 *   });
 * }
 */

/**
 * @callback Bijous~module
 * @desc A module to be loaded by {@linkcode Bijous}. This function must be the sole export of the node module's
 * entry-point.
 * @param {Bijous} context - The {@linkcode Bijous} instance loading the module
 * @param {object=} context - The {@linkcode Bijous} instance loading the module
 * @param {Bijous~moduleDone} done - The callback used to alert {@linkcode Bijous} that a module has completed loading.
 * @example
 * // We may assume this resides in a file modules/module1/index.js
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
 * @property {string} cwd - The directory where modules can be found. Defaults to the directory the module's
 * parent resides in (path.dirname(module.parent.filename))
 * @property {object} bundles - The [klect]{@link https://github.com/awnist/klect} bundles descriptor, used to find
 * modules. Defaults to {@linkcode Bijous.defaultBundles}
 * @property {object} modules - An object containing keys that represent results returned by modules when the
 * {@linkcode Bijous#load} method is called. The keys correspond with the module's filename, not including the
 * extension and will be namespaced according to the bundle's name. (e.g. modules/module1 would have a key module1 and
 * modules/module2.js would have a key module2)
 * @example
 * var Bijous = require('bijous');
 *
 * // Loads all modules
 * var bijous = new Bijous();
 * bijous.load(function () {
 *   // Access the results of module1
 *   console.log(bijous.modules.module1);
 * });
 *
 * // Overrides the cwd option and loads all modules relative to it
 * var bijous = new Bijous({
 *   cwd: '~/modules'
 * });
 * bijous.load(function () {
 *   // Access the results of module1
 *   console.log(bijous.modules.module1);
 * });
 *
 * // Overrides the bundles option and loads all modules accordingly
 * var bijous = new Bijous({
 *   bundles: 'modules/!(router)'
 * });
 * bijous.load(function () {
 *   // Access the results of module1
 *   console.log(bijous.modules.module1);
 * });
 *
 * // Overrides the bundles option with multi bundles and loads all modules
 * // one bundle's modules accordingly
 * var bijous = new Bijous({
 *   bundles: {
 *     server: 'modules/!(router)',
 *     web: ['webModules/*', 'adminModules/*']
 *   }
 * });
 * bijous.load(function () {
 *   // Access the results of module1, notice it is namespaced by the bundle
 *   // name
 *   console.log(bijous.modules.server.module1);
 *   console.log(bijous.modules.web.module2);
 * });
 */
function Bijous(options) {
  options = options || {};
  EventEmitter.call(this);

  var mod = module.parent;

  this.cwd = options.cwd || path.dirname(mod.filename);
  this.bundles = options.bundles || Bijous.defaultBundles;
  this.defaultBundleName = options.defaultBundleName || '_'
}

/**
 * Retrieves all modules found for it's bundles or a specific supplied bundle name
 * @param {string=} bundle - The name of the bundle that should be used when retrieving modules, if none is passed it
 * retrieves all bundles' modules
 * @returns {object[]} - An array of [klect]{@link https://github.com/awnist/klect} assets
 * @example
 * var Bijous = require('bijous');
 *
 * // List all modules
 * var bijous = new Bijous({
 *   bundles: {
 *     public: 'modules/public/*',
 *     private: 'modules/private/*'
 *   }
 * });
 * var allBundles = bijous.list();
 * var onlyPublicBundles = bijous.list('public');
 */
Bijous.prototype.list = function list(bundle) {
  var klect = new Klect({ cwd: this.cwd, defaultBundleName: this.defaultBundleName });
  var assets = klect.gather(this.bundles);

  if (bundle) { return assets.bundles(bundle); }
  else { return assets.bundles(); }
};

/**
 * @typedef ModuleDefinition
 * @desc An object containing the required module definition
 * @property {string} name - The module's name
 * @property {Bijous~module} module - The {@linkcode Bijous~module|module} to be loaded

/**
 * Requires all modules found for it's bundles or a specific supplied bundle name
 * @param {string=} bundle - The name of the bundle that should be used when requiring modules, if none is passed it
 * retrieves all bundles' modules
 * @returns {ModuleDefinition[]} - An array of {@linkcode ModuleDefinition|module} definitions
 * @example
 * var Bijous = require('bijous');
 *
 * // List all modules
 * var bijous = new Bijous({
 *   bundles: {
 *     public: 'modules/public/*',
 *     private: 'modules/private/*'
 *   }
 * });
 * var allBundles = bijous.require();
 * var onlyPublicBundles = bijous.require('public');
 */
Bijous.prototype.require = function req(bundle) {
  var assets = this.list(bundle);
  var self = this;
  var modules = [];

  assets.map(function (asset) {
    asset.files.map(function (file) {
      var extname = path.extname(file);
      var basename = path.basename(file, extname);
      var module = {
        name: basename,
        bundle: asset.name,
        module: require(path.join(self.cwd, file))
      };

      modules.push(module);
    });
  });

  return modules;
};

/**
 * @callback Bijous~loadCallback
 * @desc Used as a callback override for the {@linkcode Bijous#load} method. If one is specified then error handling
 * becomes it's responsibility. When one is not specified and an error occurs then the error will be thrown.
 * @param {*=} error - If an error occurs the callback will receive an error object
 * @param {*=} results - The {@linkcode Bijous#modules} property is returned
 * @example
 * var Bijous = require('bijous');
 * var bijous = new Bijous();
 * bijous.load(function (error, results) {
 *   if (error) { throw error; }
 *   console.log(results);
 * });
 */

/**
 * @event Bijous#loaded
 * @desc Fired every time a module has completed loading
 * @param {string} name - The name of the module loaded
 * @param {object} results - An object used to represent the module
 */

/**
 * @event Bijous#done
 * @desc Fired when all modules have completed loading
 * @param {Bijous} bijous - The {@linkcode Bijous} instance that loaded the modules
 */

/**
 * Requires all modules found for it's bundles or a specific supplied bundle name, and executes the async callback
 * defined by the {@linkcode Bijous~module|module}. May only be called once, subsequent calls result in an exception.
 * @param {string=} bundle - The name of the bundle that should be used when loading modules, if none is passed it
 * retrieves all bundles' modules
 * @param {Bijous~loadCallback=} callback - A callback method to use when all modules are loaded
 * @fires Bijous#loaded - Fired every time a module has completed loading
 * @fires Bijous#done - Fired when all modules have completed loading
 * @example
 * var Bijous = require('bijous');
 *
 * // Loads all modules
 * var bijous = new Bijous();
 * bijous.load();
 *
 * // Loads only modules belonging to the module1 bundle
 * bijous = new Bijous({ bundles: { module1: ['modules/module1'] }});
 * bijous.load('module1');
 *
 * // Loads all modules and executes a callback once all are loaded
 * bijous = new Bijous();
 * bijous.load(function (error, results) {
 *   if (error) { throw error; }
 *   console.log(results);
 * });
 *
 * // Loads only modules belonging to the module1 bundle and executes a callback
 * // once all are loaded
 * bijous = new Bijous({ bundles: { bundle1: ['modules/module1'] }});
 * bijous.load('bundle1', function (error, modules) {
 *   if (error) { throw error; }
 *   console.log(modules.bundle1.module1);
 * });
 */
Bijous.prototype.load = function load(bundle, callback) {
  // both bundle and callback are optional parameters
  if ('function' === typeof bundle) {
    callback = bundle;
    bundle = null;
  }

  // Get all required modules
  var modules = this.require(bundle);

  // Collection for module results
  var results = {};
  var self = this;

  // Generate callbacks used for our async series
  var fns = modules.map(function (def) {
    // Loads each module and collects the results
    return function loadModule(done) {
      // Wrapper callback used for module loading
      var cb = function (error, result) {
        // If we have a result, collect them
        if (result) {
          // Do not use a namespace if the bundle name is Klect's default name
          if (def.bundle === self.defaultBundleName) {
            results[def.name] = result;
          // Otherwise namespace the results
          } else {
            results[def.bundle] = results[def.bundle] || {};
            results[def.bundle][def.name] = result;
          }
        }

        // We are done loading the module
        self.emit('loaded', def.name, results);
        done(error);
      };

      // Begin loading the module
      def.module.call(null, self, results, cb);
    };
  });

  // Begin our async loading of all modules
  async.series(fns, function (error) {
    if (callback) { callback(error, results); }

    // If no callback has been passed and an error occurred, emit the error
    // event
    if (error && !callback) { self.emit('error', error); }
    else if (!error) { self.emit('done', results); }
  });
};

/**
 * The default bundles definition, conforms to [klect]{@link https://github.com/awnist/klect} bundles
 */
Bijous.defaultBundles = 'modules/*';

exports = module.exports = Bijous;
