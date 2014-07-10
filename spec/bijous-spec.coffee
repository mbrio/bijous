path = require 'path'
fs = require 'fs'
expect = require('chai').expect
async = require 'async'
Bijous = require '../lib/bijous'
_ = require 'lodash'

findModule = (modules, name) ->
  return true for module in modules when module.name is name

  false

describe 'Bijous', ->
  describe '#cwd', ->
    context 'when no cwd is specified', ->
      it 'should use the directory of the requiring module', ->
        bijous = new Bijous()
        expect(bijous.cwd).to.equal __dirname

    context 'when a cwd is specified', ->
      it 'should override the directory of the requiring module', ->
        src = path.join __dirname, 'src'
        expect(src).to.not.equal __dirname

        bijous = new Bijous { cwd: src }
        expect(bijous.cwd).to.equal src

  describe '#defaultBundleName', ->
    context 'when no defaultBundleName is specified', ->
      it 'should use the Bijous.defaultBundleName', ->
        bijous = new Bijous()
        expect(bijous.defaultBundleName).to.equal Bijous.defaultBundleName

    context 'when a defaultBundleName is specified', ->
      it 'should override the Bijous.defaultBundleName', ->
        cdbn = '$$'
        bijous = new Bijous
          defaultBundleName: cdbn

        expect(cdbn).to.not.equal Bijous.defaultBundleName
        expect(bijous.defaultBundleName).to.equal cdbn

    context 'when a falsy defaultBundleName is specified', ->
      it 'should use the Bijous.defaultBundleName', ->
        bijous = new Bijous
          defaultBundleName: null

        expect(bijous.defaultBundleName).to.equal Bijous.defaultBundleName

  describe '#bundles', ->
    context 'when no bundles are specified', ->
      it 'should use the default bundle pattern', ->
        bijous = new Bijous()
        expect(bijous.bundles).to.equal Bijous.defaultBundles

    context 'when bundles are specified', ->
      it 'should override the default bundle pattern', ->
        bundles =
          private: 'fixtures/modules/!(routes)'
          public: 'fixtures/public/!(routes)'

        expect(bundles).to.not.equal Bijous.defaultBundles

        bijous = new Bijous { bundles: bundles }
        expect(bijous.bundles).to.equal bundles

  describe '#list()', ->
    context 'when no bundle pattern is specified', ->
      context 'when specifying only one bundle', ->
        it 'should find all modules for all bundles', ->
          bijous = new Bijous
            bundles: 'fixtures/modules/*'

          expect(bijous.list().files()).to.have.members [
            'fixtures/modules/module1.coffee'
            'fixtures/modules/module2.coffee'
            'fixtures/modules/module3'
          ]

      context 'when specifying multiple bundles', ->
        it 'should find all modules for all bundles', ->
          bijous = new Bijous
            bundles:
              private: 'fixtures/modules/*'
              public: 'fixtures/public/*'
              empty: 'fixtures/empty/*'

          expect(bijous.list().files()).to.have.members [
            'fixtures/modules/module1.coffee'
            'fixtures/modules/module2.coffee'
            'fixtures/modules/module3'
            'fixtures/public/public1.coffee'
            'fixtures/public/public2.coffee'
          ]

    context 'when a bundle pattern is specified', ->
      it 'should find only modules pertaining to the specified bundle', ->
        bijous = new Bijous
          bundles:
            private: 'fixtures/modules/*',
            public: 'fixtures/public/*',
            empty: 'fixtures/empty/*'

        expect(bijous.list('private').files()).to.have.members [
          'fixtures/modules/module1.coffee'
          'fixtures/modules/module2.coffee'
          'fixtures/modules/module3'
        ]

        expect(bijous.list('public').files()).to.have.members [
          'fixtures/public/public1.coffee'
          'fixtures/public/public2.coffee'
        ]

        expect(bijous.list('empty').files()).to.be.empty

  describe '#require()', ->
    context 'when no bundle pattern is specified', ->
      context 'when specifying only one bundle', ->
        it 'should require all modules for all bundles', ->
          bijous = new Bijous
            bundles: 'fixtures/modules/*'

          modules = (obj.name for obj in bijous.require())
          expect(modules).to.have.members ['module1', 'module2', 'module3']

      context 'when specifying multiple bundles', ->
        it 'should require all modules for all bundles', ->
          bijous = new Bijous
            bundles:
              private: 'fixtures/modules/*'
              public: 'fixtures/public/*'
              empty: 'fixtures/empty/*'

          modules = (obj.name for obj in bijous.require())
          expect(modules).to.have.members [
            'module1', 'module2', 'module3', 'public1', 'public2'
          ]

    context 'when a bundle pattern is specified', ->
      it 'should require only modules pertaining to the specified bundle', ->
        bijous = new Bijous
          bundles:
            private: 'fixtures/modules/*'
            public: 'fixtures/public/*'
            empty: 'fixtures/empty/*'

        modules = (obj.name for obj in bijous.require 'private')
        expect(modules).to.have.members [
          'module1', 'module2', 'module3'
        ]

        modules = (obj.name for obj in bijous.require 'public')
        expect(modules).to.have.members [
          'public1', 'public2'
        ]

        modules = bijous.require 'empty'
        expect(modules).to.be.empty

  describe '#load()', ->
    it 'should load all modules', (done) ->
      bijous = new Bijous
        bundles: 'fixtures/modules/*'

      bijous.load (error, modules) ->
        expect(error).to.be.undefined
        expect(modules).to.have.keys ['module1', 'module2', 'module3']
        expect(modules.module1.name).to.equal 'module1'
        expect(modules.module2.name).to.equal 'module2'
        expect(modules.module3.name).to.equal 'module3'

        done()

    it 'should load all modules when passed multiple bundles', (done) ->
      bijous = new Bijous
        bundles:
          private: 'fixtures/modules/*'
          public: 'fixtures/public/*'
          empty: 'fixtures/empty/*'

      bijous.load (error, modules) ->
        expect(error).to.be.undefined
        expect(modules).to.have.keys ['private', 'public']
        expect(modules.private).to.have.keys ['module1', 'module2', 'module3']
        expect(modules.public).to.have.keys ['public1']

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
              private: 'fixtures/modules/*'
              public: 'fixtures/public/*'
              empty: 'fixtures/empty/*'

          bijous.load 'private', (error, modules) ->
            expect(error).to.be.undefined
            expect(modules).to.have.keys ['private']
            expect(modules.private).to.have.keys ['module1', 'module2',
              'module3']

            expect(modules.private.module1.name).to.equal 'module1'
            expect(modules.private.module2.name).to.equal 'module2'
            expect(modules.private.module3.name).to.equal 'module3'

            callback null
        (callback) ->
          bijous = new Bijous
            bundles:
              private: 'fixtures/modules/*'
              public: 'fixtures/public/*'
              empty: 'fixtures/empty/*'

          bijous.load 'public', (error, modules) ->
            expect(error).to.be.undefined
            expect(modules).to.have.keys ['public']
            expect(modules.public).to.have.keys ['public1']

            expect(modules.public.public1.name).to.equal 'public1'
            callback null
        (callback) ->
          bijous = new Bijous
            bundles:
              private: 'fixtures/modules/*'
              public: 'fixtures/public/*'
              empty: 'fixtures/empty/*'

          bijous.load 'empty', (error, modules) ->
            expect(error).to.be.undefined
            expect(Object.keys(modules)).to.be.empty
            callback null
      ],

      (err, results) ->
        done err

    it 'should load all modules and handle errors with callback', (done) ->
      bijous = new Bijous
        bundles: 'fixtures/errors/*'

      bijous.load (error, modules) ->
        expect(error).to.exist
        expect(Object.keys(modules)).to.be.empty
        done()

  describe '#loaded', ->
    it 'should emit the loaded event', (done) ->
      bijous = new Bijous
        bundles: 'fixtures/modules/*'

      loadedCount = 0

      bijous.on 'loaded', -> loadedCount++

      bijous.load (error, modules) ->
        expect(error).to.be.undefined
        expect(loadedCount).to.equal 3

        done()

  describe '#done', ->
    it 'should emit the done event', (done) ->
      bijous = new Bijous
        bundles: 'fixtures/modules/*'

      bijous.on 'done', (modules) ->
        expect(modules).to.have.keys ['module1', 'module2', 'module3']
        expect(modules.module1.name).to.equal 'module1'
        expect(modules.module2.name).to.equal 'module2'
        expect(modules.module3.name).to.equal 'module3'

        done()

      bijous.load()

  describe '#error', ->
    it 'should emit the error event', (done) ->
      bijous = new Bijous
        bundles: 'fixtures/errors/*'

      bijous.on 'error', (err) ->
        expect(err.message).to.equal 'error1'
        done()

      bijous.load()
