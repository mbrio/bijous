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

  describe('#bundles', function () {
    it ('should be the default pattern', function () {
      var bijous = new Bijous();
      bijous.bundles.should.equal(Bijous.defaultBundles);
    });

    it ('should be the pattern specified in options', function () {
      var bundles = {
        private: 'modules/!(routes)',
        public: 'public/!(routes)'
      };
      bundles.should.not.equal(Bijous.defaultBundles);

      var bijous = new Bijous({ bundles: bundles });
      bijous.bundles.should.equal(bundles);
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

    it('should find all modules when passed multiple bundles', function () {
      var bijous = new Bijous({
        bundles: {
          private: 'modules/*',
          public: 'public/*'
        }
      });
      bijous.bundles.should.not.equal(Bijous.defaultBundles);
      var modules = bijous.list().files();
      
      modules.length.should.be.exactly(2);

      fs.readdirSync(path.join(__dirname, 'modules')).map(function (f) {
        modules.indexOf(path.join('modules', f)).should.be.above(-1);
      });
    });

    it('should find modules pertaining to a specific bundle', function () {
      var bijous = new Bijous({
        bundles: {
          private: 'modules/*',
          public: 'public/*'
        }
      });
      bijous.bundles.should.not.equal(Bijous.defaultBundles);
      var modules = bijous.list('private').files();
      
      modules.length.should.be.exactly(2);

      fs.readdirSync(path.join(__dirname, 'modules')).map(function (f) {
        modules.indexOf(path.join('modules', f)).should.be.above(-1);
      });

      modules = bijous.list('public').files();
      modules.length.should.be.exactly(0);
    });
  });
});