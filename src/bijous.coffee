path = require 'path'
util = require 'util'
async = require 'async'
_ = require 'lodash'
{EventEmitter} = require 'events'
Klect = require 'klect'

# Internal: Gets a module's name based off of it's path.
#
# file - The path of the file
#
# Examples
#
#   getModuleName('/modules/module1.js')
#   # => 'module1'
#
# Returns the module's name without extension
getModuleName = (file) ->
  extname = path.extname file
  path.basename file, extname

# Public: An asynchronous module loader. Searches out modules within a file
# system using [Klect](https://github.com/awnist/klect) and supplies an
# asynchronous means of initializing them.
#
# Examples
#
#   Bijous = require 'bijous'
#
#   # Loads all modules
#   bijous = new Bijous
#   bijous.load (err, modules) ->
#     # Access the results of module1
#     console.log modules.module1
#
#   # Overrides the cwd option and loads all modules relative to it
#   bijous = new Bijous
#     cwd: '~/modules'
#   bijous.load (err, modules) ->
#     # Access the results of module1
#     console.log modules.module1
#
#   # Overrides the bundles option and loads all modules accordingly
#   bijous = new Bijous
#     bundles: 'modules/!(router)'
#   bijous.load (modules) ->
#     # Access the results of module1
#     console.log modules.module1
#
#   # Overrides the bundles option with multi bundles and loads all modules
#   # one bundle's modules accordingly
#   bijous = new Bijous
#     bundles:
#       server: 'modules/!(router)'
#       web: ['webModules/*', 'adminModules/*']
#   bijous.load (err, modules) ->
#     # Access the results of module1, notice it is namespaced by the bundle
#     # name
#     console.log modules.server.module1
#     console.log modules.web.module2
class Bijous extends EventEmitter
  @defaultBundles: 'modules/*'
  @defaultBundleName: '_'

  constructor: ({@cwd, @bundles, @defaultBundleName} = {}) ->
    @cwd ?= path.dirname module.parent.filename
    @bundles ?= Bijous.defaultBundles
    @defaultBundleName ?= Bijous.defaultBundleName

  list: (bundle) ->
    klect = new Klect
      cwd: @cwd
      defaultBundleName: @defaultBundleName

    klect.gather(@bundles).bundles bundle

  require: (bundle) ->
    _.flatten @list(bundle).map (asset) =>
      asset.files.map (file) =>
        name: getModuleName file
        bundle: asset.name
        module: require path.join(@cwd, file)

  loadModule: (def, results, done) ->
    def.module.call null, @, results, (error, result) =>
      if result
        if def.bundle == @defaultBundleName then results[def.name] = result
        else _.merge results[def.bundle] ?= {}, _.object([def.name], [result])

      @emit 'loaded', def.name, results unless error
      done error

  load: (bundle, callback) ->
    [callback, bundle] = [bundle, null] if 'function' == typeof bundle
    results = {}

    fns = @require(bundle).map (def) => (done) => @loadModule def, results, done

    async.series fns, (error) =>
      if callback then callback error, results

      if error and not callback then @emit 'error', error
      else if not error then @emit 'done', results

exports = module.exports = Bijous
