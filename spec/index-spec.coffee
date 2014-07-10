path = require 'path'
fs = require 'fs'
expect = require('chai').expect
async = require 'async'
Bijous = require '../lib/bijous'

findModule = (modules, name) ->
  return true for module in modules when module.name is name

  false

describe 'Bijous', ->
  describe '#cwd', ->
    it 'should be the directory of the requiring module', ->
      bijous = new Bijous()
      expect(bijous.cwd).to.equal __dirname

    it 'should be the directory specified in options', ->
      src = path.join __dirname, 'src'
      expect(src).to.not.equal __dirname

      bijous = new Bijous { cwd: src }
      expect(bijous.cwd).to.equal src

  describe '#bundles', ->
    it 'should be the default pattern', ->
      bijous = new Bijous()
      expect(bijous.bundles).to.equal Bijous.defaultBundles

    it 'should be the pattern specified in options', ->
      bundles =
        private: 'modules/!(routes)'
        public: 'public/!(routes)'

      expect(bundles).to.not.equal Bijous.defaultBundles

      bijous = new Bijous { bundles: bundles }
      expect(bijous.bundles).to.equal bundles

  describe '#list()', ->
    it 'should find all modules', ->
      bijous = new Bijous()
      modules = bijous.list().files()

      expect(modules.length).to.equal 3

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        expect(modules.indexOf(path.join('modules', f))).to.be.above -1

    it 'should find all modules when passed multiple bundles', ->
      bijous = new Bijous
        bundles:
          private: 'modules/*'
          public: 'public/*'
          empty: 'empty/*'

      expect(bijous.bundles).to.not.equal Bijous.defaultBundles
      modules = bijous.list().files()

      expect(modules.length).to.equal 5

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        expect(modules.indexOf(path.join('modules', f))).to.be.above -1

      fs.readdirSync(path.join(__dirname, 'public')).map (f) ->
        expect(modules.indexOf(path.join('public', f))).to.be.above -1

    it 'should find modules pertaining to a specific bundle', ->
      bijous = new Bijous
        bundles:
          private: 'modules/*',
          public: 'public/*',
          empty: 'empty/*'

      expect(bijous.bundles).to.not.equal Bijous.defaultBundles

      modules = bijous.list('private').files()
      expect(modules.length).to.equal 3

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        expect(modules.indexOf(path.join('modules', f))).to.be.above -1

      modules = bijous.list('public').files()
      expect(modules.length).equal 2

      fs.readdirSync(path.join(__dirname, 'public')).map (f) ->
        expect(modules.indexOf(path.join('public', f))).to.be.above -1

      modules = bijous.list('empty').files()
      expect(modules.length).to.equal 0

  describe '#require()', ->
    it 'should require all modules', ->
      bijous = new Bijous()
      modules = bijous.require()
      expect(modules.length).to.equal 3

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        expect(found).to.equal true

    it 'should require all modules when passed multiple bundles', ->
      bijous = new Bijous
        bundles:
          private: 'modules/*'
          public: 'public/*'
          empty: 'empty/*'

      expect(bijous.bundles).to.not.equal Bijous.defaultBundles
      modules = bijous.require()
      expect(modules.length).to.equal 5

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        expect(found).to.equal true

      fs.readdirSync(path.join(__dirname, 'public')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        expect(found).to.equal true

    it 'should require modules pertaining to a specific bundle', ->
      bijous = new Bijous
        bundles:
          private: 'modules/*'
          public: 'public/*'
          empty: 'empty/*'

      expect(bijous.bundles).to.not.equal Bijous.defaultBundles

      modules = bijous.require 'private'
      expect(modules.length).to.equal 3

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        expect(found).to.equal true

      modules = bijous.require 'public'
      expect(modules.length).to.equal 2

      fs.readdirSync(path.join(__dirname, 'public')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        expect(found).to.equal true

      modules = bijous.require 'empty'
      expect(modules.length).to.equal 0

  describe '#load()', ->
    it 'should load all modules', (done) ->
      bijous = new Bijous()

      bijous.load (error, modules) ->
        expect(error).to.be.undefined
        expect(Object.keys(modules).length).to.equal 3
        expect(modules.module1.name).to.equal 'module1'
        expect(modules.module2.name).to.equal 'module2'
        expect(modules.module3.name).to.equal 'module3'

        done()

    it 'should load all modules when passed multiple bundles', (done) ->
      bijous = new Bijous
        bundles:
          private: 'modules/*'
          public: 'public/*'
          empty: 'empty/*'

      expect(bijous.bundles).to.not.equal Bijous.defaultBundles

      bijous.load (error, modules) ->
        expect(error).to.be.undefined
        expect(Object.keys(modules).length).to.equal 2
        expect(Object.keys(modules.private).length).to.equal 3
        expect(Object.keys(modules.public).length).to.equal 1

        expect(modules.private.module1.name).to.equal 'module1'
        expect(modules.private.module2.name).to.equal 'module2'
        expect(modules.private.module3.name).to.equal 'module3'
        expect(modules.public.public1.name).to.equal 'public1'

        done()

    it 'should load all modules pertaining to a specific bundle', (done) ->
      async.series [
        (callback) ->
          bijous = new Bijous
            bundles:
              private: 'modules/*'
              public: 'public/*'
              empty: 'empty/*'

          expect(bijous.bundles).to.not.equal Bijous.defaultBundles

          bijous.load 'private', (error, modules) ->
            expect(error).to.be.undefined
            expect(Object.keys(modules).length).to.equal 1
            expect(Object.keys(modules.private).length).to.equal 3
            expect(modules.private.module1.name).to.equal 'module1'
            expect(modules.private.module2.name).to.equal 'module2'
            expect(modules.private.module3.name).to.equal 'module3'

            callback null
        (callback) ->
          bijous = new Bijous
            bundles:
              private: 'modules/*'
              public: 'public/*'
              empty: 'empty/*'

          expect(bijous.bundles).to.not.equal Bijous.defaultBundles

          bijous.load 'public', (error, modules) ->
            expect(error).to.be.undefined
            expect(Object.keys(modules).length).to.equal 1
            expect(Object.keys(modules.public).length).to.equal 1
            expect(modules.public.public1.name).to.equal 'public1'
            callback null
        (callback) ->
          bijous = new Bijous
            bundles:
              private: 'modules/*'
              public: 'public/*'
              empty: 'empty/*'

          expect(bijous.bundles).to.not.equal Bijous.defaultBundles

          bijous.load 'empty', (error, modules) ->
            expect(error).to.be.undefined
            expect(Object.keys(modules).length).to.equal 0
            callback null
      ],

      (err, results) ->
        done err

    it 'should load all modules and handle errors with callback', (done) ->
      bijous = new Bijous
        bundles: 'errors/*'

      expect(bijous.bundles).to.not.equal Bijous.defaultBundles

      bijous.load (error, modules) ->
        expect(error).to.be.ok
        expect(Object.keys(modules).length).to.equal 0
        done()

  describe '#loaded', ->
    it 'should emit the loaded event', (done) ->
      bijous = new Bijous()
      loadedCount = 0

      bijous.on 'loaded', -> loadedCount++

      bijous.load (error, modules) ->
        expect(error).to.be.undefined
        expect(loadedCount).to.equal 3

        done()

  describe '#done', ->
    it 'should emit the done event', (done) ->
      bijous = new Bijous()

      bijous.on 'done', (modules) ->
        expect(Object.keys(modules).length).to.equal 3
        expect(modules.module1.name).to.equal 'module1'
        expect(modules.module2.name).to.equal 'module2'
        expect(modules.module3.name).to.equal 'module3'

        done()

      bijous.load()

  describe '#error', ->
    it 'should emit the error event', (done) ->
      bijous = new Bijous
        bundles: 'errors/*'

      expect(bijous.bundles).to.not.equal Bijous.defaultBundles

      bijous.on 'error', (err) ->
        expect(err.message).to.equal 'error1'
        done()

      bijous.load()
