var Bijous, EventEmitter, Klect, exports, getModuleName, loadModule, path, series, setService, util, _,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

path = require('path');

util = require('util');

series = require('array-series');

_ = require('underscore-plus');

EventEmitter = require('events').EventEmitter;

Klect = require('klect');

getModuleName = function(file) {
  var extname;
  extname = path.extname(file);
  return path.basename(file, extname);
};

loadModule = function(def, services, done) {
  def.module.call(null, this, services, (function(_this) {
    return function(error, service) {
      if (service) {
        setService.call(_this, def, services, service);
      }
      if (!error) {
        _this.emit('loaded', def.name, def.bundle, services);
      }
      return done(error);
    };
  })(this));
};

setService = function(def, services, service) {
  var _name;
  if (def.bundle === this.defaultBundleName) {
    services[def.name] = service;
  } else {
    _.extend(services[_name = def.bundle] != null ? services[_name] : services[_name] = {}, _.object([def.name], [service]));
  }
};

Bijous = (function(_super) {
  __extends(Bijous, _super);

  Bijous.defaultBundles = 'modules/*';

  Bijous.defaultBundleName = '_';

  function Bijous(_arg) {
    var _ref;
    _ref = _arg != null ? _arg : {}, this.cwd = _ref.cwd, this.bundles = _ref.bundles, this.defaultBundleName = _ref.defaultBundleName;
    if (this.cwd == null) {
      this.cwd = path.dirname(module.parent.filename);
    }
    if (this.bundles == null) {
      this.bundles = Bijous.defaultBundles;
    }
    if (this.defaultBundleName == null) {
      this.defaultBundleName = Bijous.defaultBundleName;
    }
  }

  Bijous.prototype.list = function(bundle) {
    var klect;
    klect = new Klect({
      cwd: this.cwd,
      defaultBundleName: this.defaultBundleName
    });
    return klect.gather(this.bundles).bundles(bundle);
  };

  Bijous.prototype.require = function(bundle) {
    return _.flatten(this.list(bundle).map((function(_this) {
      return function(asset) {
        return asset.files.map(function(file) {
          return {
            name: getModuleName(file),
            bundle: asset.name,
            module: require(path.join(_this.cwd, file))
          };
        });
      };
    })(this)));
  };

  Bijous.prototype.load = function(bundle, callback) {
    var fns, services, _ref;
    if ('function' === typeof bundle) {
      _ref = [bundle, null], callback = _ref[0], bundle = _ref[1];
    }
    services = {};
    fns = this.require(bundle).map((function(_this) {
      return function(def) {
        return function(done) {
          return loadModule.call(_this, def, services, done);
        };
      };
    })(this));
    series(fns, (function(_this) {
      return function(error) {
        if (callback) {
          callback(error, services);
        }
        if (error && !callback) {
          return _this.emit('error', error);
        } else if (!error) {
          return _this.emit('done', services);
        }
      };
    })(this));
  };

  return Bijous;

})(EventEmitter);

exports = module.exports = Bijous;
