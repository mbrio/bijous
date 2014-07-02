'use strict';

var path = require('path');
var util = require('util');
var async = require('async');
var EventEmitter = require('events').EventEmitter;
var Klect = require('klect');

util.inherits(Bijous, EventEmitter);
function Bijous(options) {
  options = options || {};
  EventEmitter.call(this);

  var mod = module.parent || module;

  this.cwd = options.cwd || path.dirname(mod.filename);
  this.bundles = options.bundles || Bijous.defaultBundles;
  this.loaded = {};
}

Bijous.prototype.list = function list(bundle) {
  var klect = new Klect({ cwd: this.cwd });
  var assets = klect.gather(this.bundles);

  if (bundle) { return assets.bundles(bundle); }
  else { return assets; }
};

// Bijous.prototype.load = function load(callback) {
//   var klect = new Klect({ cwd: this.cwd });
//   var assets = klect.gather(this.modulesPattern);
//   var self = this;
  
//   var fns = assets.map(function (file) {
//     var basename = path.basename(file);

//     return function loadAsset(done) {
//       var cb = function (error, results) {
//         if (results) {
//           self.modules[basename] = results;
//         }

//         self.emit('loaded', basename, results);
//         done(error, results);
//       };

//       require(path.join(self.cwd, file)).call(null, self, cb);
//     };
//   });

//   async.series(fns, function (error, results) {
//     if (callback) { callback(error, results); }
//     else if (error) { throw error; }

//     self.emit('done', self);
//   });
// };

Bijous.defaultBundles = 'modules/*';

exports = module.exports = Bijous;