'use strict';

/* global describe, it */

var path = require('path');
var assert = require('assert');
var fs = require('fs');
var should = require('should');
var Bijous = require('../index');

describe('Bijous', function () {
  describe('#cwd', function () {
    it('should be the directory of the requiring module', function () {
      var bijous = new Bijous();
      bijous.cwd.should.equal(__dirname);
    });

    it ('should be the directory specified in options', function () {
      var src = path.join(__dirname, 'src');
      src.should.not.equal(__dirname);

      var bijous = new Bijous({ cwd: src });
      bijous.cwd.should.equal(src);
    });
  });

  describe('#modulesPattern', function () {
    it ('should be the default pattern', function () {
      var bijous = new Bijous();
      bijous.modulesPattern.should.equal(Bijous.defaultModulePattern);
    });

    it ('should be the pattern specified in options', function () {
      var modulesPattern = 'modules/!(routes)';
      modulesPattern.should.not.equal(Bijous.defaultModulePattern);

      var bijous = new Bijous({ modulesPattern: modulesPattern });
      bijous.modulesPattern.should.equal(modulesPattern);
    });
  });

  describe('#loaded', function () {
    it('should be no loaded modules', function () {
      var bijous = new Bijous();
      var keys = Object.keys(bijous.loaded);
      keys.length.should.be.exactly(0);
    });
  });

  describe('#list()', function () {
    it('should find all modules', function () {
      var bijous = new Bijous();
      var modules = bijous.list().files();
      
      modules.length.should.be.exactly(2);

      fs.readdirSync(path.join(__dirname, 'modules')).map(function (f) {
        modules.indexOf(path.join('modules', f)).should.be.above(-1);
      });
    });
  });
});

//   // should find all modules
//   (function () {
//     var bijous = new Bijous();
//     var modules = bijous.list().files();
    
//     console.log(modules);
//     assert(modules.length === 2);

//     fs.readdirSync(path.join(__dirname, 'modules')).map(function (f) {
//       assert(modules.indexOf(path.join('modules', f)) !== -1);
//     });
//   })();
// })();