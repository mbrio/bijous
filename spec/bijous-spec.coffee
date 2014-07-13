path = require 'path'
fs = require 'fs'
expect = require('chai').expect
series = require 'array-series'
sinon = require 'sinon'
Bijous = require '../lib/bijous'

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
      context 'and when specifying only one bundle', ->
        it 'should find all modules for all bundles', ->
          bijous = new Bijous
            bundles: 'fixtures/modules/*'

          expect(bijous.list().files()).to.have.members [
            'fixtures/modules/module1.coffee'
            'fixtures/modules/module2.coffee'
            'fixtures/modules/module3'
          ]

      context 'and when specifying multiple bundles', ->
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
            'fixtures/public/public-server.coffee'
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
          'fixtures/public/public-server.coffee'
        ]

        expect(bijous.list('empty').files()).to.be.empty

  describe '#require()', ->
    context 'when no bundle pattern is specified', ->
      context 'and when specifying only one bundle', ->
        it 'should require all modules for all bundles', ->
          bijous = new Bijous
            bundles: 'fixtures/modules/*'

          modules = (obj.name for obj in bijous.require())
          expect(modules).to.have.members ['module1', 'module2', 'module3']

      context 'and when specifying multiple bundles', ->
        it 'should require all modules for all bundles', ->
          bijous = new Bijous
            bundles:
              private: 'fixtures/modules/*'
              public: 'fixtures/public/*'
              empty: 'fixtures/empty/*'

          modules = (obj.name for obj in bijous.require())
          expect(modules).to.have.members [
            'module1', 'module2', 'module3', 'public1', 'public2',
            'publicServer']

    context 'when a bundle pattern is specified', ->
      it 'should require only modules pertaining to the specified bundle', ->
        bijous = new Bijous
          bundles:
            private: 'fixtures/modules/*'
            public: 'fixtures/public/*'
            empty: 'fixtures/empty/*'

        modules = (obj.name for obj in bijous.require 'private')
        expect(modules).to.have.members [
          'module1', 'module2', 'module3']

        modules = (obj.name for obj in bijous.require 'public')
        expect(modules).to.have.members [
          'public1', 'public2', 'publicServer']

        modules = bijous.require 'empty'
        expect(modules).to.be.empty

  describe '#load()', ->
    context 'when no bundle pattern is specified', ->
      context 'and when specifying only one bundle', ->
        it 'should load all modules for all bundles', (done) ->
          bijous = new Bijous
            bundles: 'fixtures/modules/*'

          bijous.load (error, services) ->
            expect(error).to.be.undefined
            expect(services).to.have.keys ['module1', 'module2', 'module3']

            names = (obj.name for key, obj of services)
            expect(names).to.have.members ['module1', 'module2', 'module3']

            done()

      context 'and when specifying multiple bundles', ->
        it 'should load all modules for all bundles', (done) ->
          bijous = new Bijous
            bundles:
              private: 'fixtures/modules/*'
              public: 'fixtures/public/*'
              empty: 'fixtures/empty/*'

          bijous.load (error, services) ->
            expect(error).to.be.undefined
            expect(services).to.have.keys ['private', 'public']
            expect(services.private).to.have.keys [ 'module1', 'module2',
              'module3']
            expect(services.public).to.have.keys ['public1', 'publicServer']

            names = (obj.name for key, obj of services.private)
            expect(names).to.have.members ['module1', 'module2', 'module3']

            names = (obj.name for key, obj of services.public)
            expect(names).to.have.members ['public1', 'public-server']

            done()

    context 'when a bundle pattern is specified', ->
      it 'should load all modules pertaining to a specific bundle', (done) ->
        bijous = new Bijous
          bundles:
            private: 'fixtures/modules/*'
            public: 'fixtures/public/*'
            empty: 'fixtures/empty/*'

        fns = [
          (callback) ->
            bijous.load 'private', (error, services) ->
              expect(error).to.be.undefined
              expect(services).to.have.keys ['private']
              expect(services.private).to.have.keys ['module1', 'module2',
                'module3']

              names = (obj.name for key, obj of services.private)
              expect(names).to.have.members ['module1', 'module2', 'module3']

              callback error
          (callback) ->
            bijous.load 'public', (error, services) ->
              expect(error).to.be.undefined
              expect(services).to.have.keys ['public']
              expect(services.public).to.have.keys ['public1', 'publicServer']

              names = (obj.name for key, obj of services.public)
              expect(names).to.have.members ['public1', 'public-server']

              callback error
          (callback) ->
            bijous.load 'empty', (error, services) ->
              expect(error).to.be.undefined
              expect(Object.keys(services)).to.be.empty
              callback error
        ]

        series fns, done

    context 'when an error occurs while loading a module', ->
      bijous = null
      beforeEach -> bijous = new Bijous { bundles: 'fixtures/errors/*' }

      context 'and when a callback is supplied', ->
        it 'should handle errors with callback', (done) ->
          bijous.load (error, services) ->
            expect(error).to.exist
            expect(Object.keys(services)).to.be.empty
            done()

        it 'should not emit the error event', (done) ->
          callback = sinon.spy()
          bijous.on 'error', callback

          bijous.load (error, services) ->
            cb = ->
              expect(callback.called).to.be.false
              done()

            setTimeout cb, 100

      context 'and when no callback is supplied', ->
        it 'should emit the *error* event', (done) ->
          bijous.on 'error', (err) ->
            expect(err).to.exist
            expect(err.message).to.equal 'error1'
            done()

          bijous.load()

    context 'when an individual module has completed loading successfully', ->
      it 'should emit the *loaded* event and return any service', (done) ->
        bijous = new Bijous { bundles: 'fixtures/modules/*' }

        callback = sinon.spy()
        bijous.on 'loaded', callback

        bijous.load (error, services) ->
          expect(error).to.be.undefined
          expect(callback.calledThrice).to.be.true

          done()

    context 'when all modules have completed loading successfully', ->
      it 'should emit the *done* event and return any services', (done) ->
        bijous = new Bijous { bundles: 'fixtures/modules/*' }

        bijous.on 'done', (services) ->
          expect(services).to.have.keys ['module1', 'module2', 'module3']
          names = (obj.name for key, obj of services)
          expect(names).to.have.members ['module1', 'module2', 'module3']

          done()

        bijous.load()
