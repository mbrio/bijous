path = require 'path'
fs = require 'fs'
should = require 'should'
async = require 'async'
Bijous = require '../lib/bijous'

findModule = (modules, name) ->
  return true for module in modules when module.name == name

  false

describe 'Bijous', ->
  describe '#cwd', ->
    it 'should be the directory of the requiring module', ->
      bijous = new Bijous
      bijous.cwd.should.equal __dirname

    it 'should be the directory specified in options', ->
      src = path.join __dirname, 'src'
      src.should.not.equal __dirname

      bijous = new Bijous { cwd: src }
      bijous.cwd.should.equal src

  describe '#bundles', ->
    it 'should be the default pattern', ->
      bijous = new Bijous
      bijous.bundles.should.equal Bijous.defaultBundles

    it 'should be the pattern specified in options', ->
      bundles =
        private: 'modules/!(routes)'
        public: 'public/!(routes)'

      bundles.should.not.equal Bijous.defaultBundles

      bijous = new Bijous { bundles: bundles }
      bijous.bundles.should.equal bundles

  describe '#list()', ->
    it 'should find all modules', ->
      bijous = new Bijous
      modules = bijous.list().files()

      modules.length.should.be.exactly 3

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        modules.indexOf(path.join('modules', f)).should.be.above -1

    it 'should find all modules when passed multiple bundles', ->
      bijous = new Bijous
        bundles:
          private: 'modules/*'
          public: 'public/*'
          empty: 'empty/*'

      bijous.bundles.should.not.equal Bijous.defaultBundles
      modules = bijous.list().files()

      modules.length.should.be.exactly 5

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        modules.indexOf(path.join('modules', f)).should.be.above -1

      fs.readdirSync(path.join(__dirname, 'public')).map (f) ->
        modules.indexOf(path.join('public', f)).should.be.above -1

    it 'should find modules pertaining to a specific bundle', ->
      bijous = new Bijous
        bundles:
          private: 'modules/*',
          public: 'public/*',
          empty: 'empty/*'

      bijous.bundles.should.not.equal Bijous.defaultBundles

      modules = bijous.list('private').files()
      modules.length.should.be.exactly 3

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        modules.indexOf(path.join('modules', f)).should.be.above -1

      modules = bijous.list('public').files()
      modules.length.should.be.exactly 2

      fs.readdirSync(path.join(__dirname, 'public')).map (f) ->
        modules.indexOf(path.join('public', f)).should.be.above -1

      modules = bijous.list('empty').files()
      modules.length.should.be.exactly 0

  describe '#require()', ->
    it 'should require all modules', ->
      bijous = new Bijous
      modules = bijous.require()
      modules.length.should.be.exactly 3

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        found.should.equal true

    it 'should require all modules when passed multiple bundles', ->
      bijous = new Bijous
        bundles:
          private: 'modules/*'
          public: 'public/*'
          empty: 'empty/*'

      bijous.bundles.should.not.equal Bijous.defaultBundles
      modules = bijous.require()
      modules.length.should.be.exactly 5

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        found.should.equal true

      fs.readdirSync(path.join(__dirname, 'public')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        found.should.equal true

    it 'should require modules pertaining to a specific bundle', ->
      bijous = new Bijous
        bundles:
          private: 'modules/*'
          public: 'public/*'
          empty: 'empty/*'

      bijous.bundles.should.not.equal Bijous.defaultBundles

      modules = bijous.require 'private'
      modules.length.should.be.exactly 3

      fs.readdirSync(path.join(__dirname, 'modules')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        found.should.equal true

      modules = bijous.require 'public'
      modules.length.should.be.exactly 2

      fs.readdirSync(path.join(__dirname, 'public')).map (f) ->
        extname = path.extname f
        basename = path.basename f, extname

        found = findModule modules, basename
        found.should.equal true

      modules = bijous.require 'empty'
      modules.length.should.be.exactly 0

  describe '#load()', ->
    it 'should load all modules', (done) ->
      bijous = new Bijous

      bijous.load (error, modules) ->
        should(error).not.be.ok
        Object.keys(modules).length.should.be.exactly 3
        modules.module1.name.should.equal 'module1'
        modules.module2.name.should.equal 'module2'
        modules.module3.name.should.equal 'module3'

        done()

    it 'should load all modules when passed multiple bundles', (done) ->
      bijous = new Bijous
        bundles:
          private: 'modules/*'
          public: 'public/*'
          empty: 'empty/*'

      bijous.bundles.should.not.equal Bijous.defaultBundles

      bijous.load (error, modules) ->
        should(error).not.be.ok
        Object.keys(modules).length.should.be.exactly 2
        Object.keys(modules.private).length.should.be.exactly 3
        Object.keys(modules.public).length.should.be.exactly 1

        modules.private.module1.name.should.equal 'module1'
        modules.private.module2.name.should.equal 'module2'
        modules.private.module3.name.should.equal 'module3'
        modules.public.public1.name.should.equal 'public1'

        done()

    it 'should load all modules pertaining to a specific bundle', (done) ->
      async.series [
        (callback) ->
          bijous = new Bijous
            bundles:
              private: 'modules/*'
              public: 'public/*'
              empty: 'empty/*'

          bijous.bundles.should.not.equal Bijous.defaultBundles

          bijous.load 'private', (error, modules) ->
            should(error).not.be.ok
            Object.keys(modules).length.should.be.exactly 1
            Object.keys(modules.private).length.should.be.exactly 3
            modules.private.module1.name.should.equal 'module1'
            modules.private.module2.name.should.equal 'module2'
            modules.private.module3.name.should.equal 'module3'

            callback null
        (callback) ->
          bijous = new Bijous
            bundles:
              private: 'modules/*'
              public: 'public/*'
              empty: 'empty/*'

          bijous.bundles.should.not.equal Bijous.defaultBundles

          bijous.load 'public', (error, modules) ->
            should(error).not.be.ok
            Object.keys(modules).length.should.be.exactly 1
            Object.keys(modules.public).length.should.be.exactly 1
            modules.public.public1.name.should.equal 'public1'
            callback null
        (callback) ->
          bijous = new Bijous
            bundles:
              private: 'modules/*'
              public: 'public/*'
              empty: 'empty/*'

          bijous.bundles.should.not.equal Bijous.defaultBundles

          bijous.load 'empty', (error, modules) ->
            should(error).not.be.ok
            Object.keys(modules).length.should.be.exactly 0
            callback null
      ],

      (err, results) ->
        done err

    it 'should load all modules and handle errors with callback', (done) ->
      bijous = new Bijous
        bundles: 'errors/*'

      bijous.bundles.should.not.equal Bijous.defaultBundles

      bijous.load (error, modules) ->
        error.should.be.ok
        Object.keys(modules).length.should.be.exactly 0
        done()

  describe '#loaded', ->
    it 'should emit the loaded event', (done) ->
      bijous = new Bijous
      loadedCount = 0

      bijous.on 'loaded', -> loadedCount++

      bijous.load (error, modules) ->
        should(error).not.be.ok
        loadedCount.should.equal 3

        done()

  describe '#done', ->
    it 'should emit the done event', (done) ->
      bijous = new Bijous

      bijous.on 'done', (modules) ->
        Object.keys(modules).length.should.be.exactly 3
        modules.module1.name.should.equal 'module1'
        modules.module2.name.should.equal 'module2'
        modules.module3.name.should.equal 'module3'

        done()

      bijous.load()

  describe '#error', ->
    it 'should emit the error event', (done) ->
      bijous = new Bijous
        bundles: 'errors/*'

      bijous.bundles.should.not.equal Bijous.defaultBundles

      bijous.on 'error', (err) ->
        err.message.should.equal 'error1'
        done()

      bijous.load()
