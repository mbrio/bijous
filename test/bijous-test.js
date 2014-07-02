'use strict';

/* global describe, it */

var path = require('path');
var assert = require('assert');
var fs = require('fs');
var should = require('should');
var async = require('async');
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

  describe('#modules', function () {
    it('should be no loaded modules', function () {
      var bijous = new Bijous();
      var keys = Object.keys(bijous.modules);
      keys.length.should.be.exactly(0);
    });
  });

  describe('#list()', function () {
    it('should find all modules', function () {
      var bijous = new Bijous();
      var modules = bijous.list().files();
      
      modules.length.should.be.exactly(3);

      fs.readdirSync(path.join(__dirname, 'modules')).map(function (f) {
        modules.indexOf(path.join('modules', f)).should.be.above(-1);
      });
    });

    it('should find all modules when passed multiple bundles', function () {
      var bijous = new Bijous({
        bundles: {
          private: 'modules/*',
          public: 'public/*',
          empty: 'empty/*'
        }
      });
      bijous.bundles.should.not.equal(Bijous.defaultBundles);
      var modules = bijous.list().files();
      
      modules.length.should.be.exactly(5);

      fs.readdirSync(path.join(__dirname, 'modules')).map(function (f) {
        modules.indexOf(path.join('modules', f)).should.be.above(-1);
      });

      fs.readdirSync(path.join(__dirname, 'public')).map(function (f) {
        modules.indexOf(path.join('public', f)).should.be.above(-1);
      });
    });

    it('should find modules pertaining to a specific bundle', function () {
      var bijous = new Bijous({
        bundles: {
          private: 'modules/*',
          public: 'public/*',
          empty: 'empty/*'
        }
      });
      bijous.bundles.should.not.equal(Bijous.defaultBundles);
      
      var modules = bijous.list('private').files();
      modules.length.should.be.exactly(3);

      fs.readdirSync(path.join(__dirname, 'modules')).map(function (f) {
        modules.indexOf(path.join('modules', f)).should.be.above(-1);
      });

      modules = bijous.list('public').files();
      modules.length.should.be.exactly(2);

      fs.readdirSync(path.join(__dirname, 'public')).map(function (f) {
        modules.indexOf(path.join('public', f)).should.be.above(-1);
      });

      modules = bijous.list('empty').files();
      modules.length.should.be.exactly(0);
    });
  });

  describe('#require()', function () {
    it('should load all modules', function (done) {
      var bijous = new Bijous();
      bijous.require(function (error, results) {
        should(error).not.be.ok; // jshint ignore:line
        Object.keys(bijous.modules).length.should.be.exactly(3);
        bijous.modules.module1.name.should.equal('module1');
        bijous.modules.module2.name.should.equal('module2');
        bijous.modules.module3.name.should.equal('module3');
        done();
      });
    });

    it('should load all modules when passed multiple bundles', function (done) {
      var bijous = new Bijous({
        bundles: {
          private: 'modules/*',
          public: 'public/*',
          empty: 'empty/*'
        }
      });
      bijous.bundles.should.not.equal(Bijous.defaultBundles);

      bijous.require(function (error, results) {
        should(error).not.be.ok; // jshint ignore:line
        Object.keys(bijous.modules).length.should.be.exactly(4);
        bijous.modules.module1.name.should.equal('module1');
        bijous.modules.module2.name.should.equal('module2');
        bijous.modules.module3.name.should.equal('module3');
        bijous.modules.public1.name.should.equal('public1');
        done();
      });
    });

    it('should load all modules pertaining to a specific bundle', function (done) {
      async.series([
        function (callback) {
          var bijous = new Bijous({
            bundles: {
              private: 'modules/*',
              public: 'public/*',
              empty: 'empty/*'
            }
          });
          bijous.bundles.should.not.equal(Bijous.defaultBundles);

          bijous.require('private', function (error, results) {
            should(error).not.be.ok; // jshint ignore:line
            Object.keys(bijous.modules).length.should.be.exactly(3);
            bijous.modules.module1.name.should.equal('module1');
            bijous.modules.module2.name.should.equal('module2');
            bijous.modules.module3.name.should.equal('module3');
            callback(null);
          });
        },
        function (callback) {
          var bijous = new Bijous({
            bundles: {
              private: 'modules/*',
              public: 'public/*',
              empty: 'empty/*'
            }
          });
          bijous.bundles.should.not.equal(Bijous.defaultBundles);

          bijous.require('public', function (error, results) {
            should(error).not.be.ok; // jshint ignore:line
            Object.keys(bijous.modules).length.should.be.exactly(1);
            bijous.modules.public1.name.should.equal('public1');
            callback(null);
          });
        },
        function (callback) {
          var bijous = new Bijous({
            bundles: {
              private: 'modules/*',
              public: 'public/*',
              empty: 'empty/*'
            }
          });
          bijous.bundles.should.not.equal(Bijous.defaultBundles);
          
          bijous.require('empty', function (error, results) {
            should(error).not.be.ok; // jshint ignore:line
            Object.keys(bijous.modules).length.should.be.exactly(0);
            callback(null);
          });
        }
      ], function (err, results) {
        done(err);
      });
    });

    it('should load all modules and handle errors with callback', function (done) {
      var bijous = new Bijous({
        bundles: 'errors/*'
      });
      bijous.bundles.should.not.equal(Bijous.defaultBundles);

      bijous.require(function (error, results) {
        should(error).be.ok; // jshint ignore:line
        Object.keys(bijous.modules).length.should.be.exactly(0);
        done();
      });
    });

    it('should load all modules and throw errors without callback', function (done) {
      var bijous = new Bijous({
        bundles: 'errors/*'
      });
      bijous.bundles.should.not.equal(Bijous.defaultBundles);

      try {
        bijous.require();
        should(false).be.ok; // jshint ignore:line
      } catch (err) {
        err.should.be.ok; // jshint ignore:line
        done();
      }
    });
  });
});