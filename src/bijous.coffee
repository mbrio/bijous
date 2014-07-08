path = require 'path'
util = require 'util'
async = require 'async'
_ = require 'lodash'
{EventEmitter} = require 'events'
Klect = require 'klect'

# Public: Determines a module's name using it's path.
#
# file - The path of the file as a {String}
#
# ```coffee
# getModuleName('/modules/module1.js')
# # => 'module1'
# ```
#
# Returns: A {String} representing the module's name without extension
getModuleName = (file) ->
  extname = path.extname file
  path.basename file, extname


# Public: Loads a singular module as described by {Bijous}. Handles populating
# the module's result object.
#
# def     - The module's definition as an {Object} with the following keys:
#           :name - The module's name
#           :bundle - The bundle's name
#           :module - The module's load function
# results - The results of all previously loaded modules as an {Object}
# done    - Alerts bijous when the module has loaded, is a {Function}, the first
#           argument will be an {Error} if one has occurred.
#
# Emits loaded when a module has successfully loaded. The first argument will be
#   a {String} representing the module's name, the second argument will be a
#   {String} representing the bundle's name, the third argument will be an
#   {Object} containing the results of the module's execution.
#
# Returns: `undefined`
loadModule = (def, results, done) ->
  def.module.call null, @, results, (error, result) =>
    setResult.call(this, def, results, result) if result

    @emit 'loaded', def.name, def.bundle, results unless error
    done error

  return

# Public: Sets a module's result, the result will be namespaced if the bundle
# name is not the {Bijous.defaultBundleName}.
#
# def     - The module's definition as an {Object} with the following keys:
#           :name - The module's name
#           :bundle - The bundle's name
#           :module - The module's load function
# results - The results of all previously loaded modules as an {Object}
# result  - The result of the currently loaded module as an {Object}.
#
# ## Default Bundles Have No Namespace
#
# ```coffee
# Bijous = require 'bijous'
#
# # We define a new {Bijous} instance, using the default bundle configuration.
# # This causes klect to use the {Bijous.defaultBundleName}, and bijous to
# # store results without a namespace
# bijous = new Bijous()
#
# # We assume there is a module called *module1*
# bijous.load (err, modules) ->
#   console.log modules.module1
#
# # We define a new {Bijous} instance, specifying a bundle configuration with no
# # name. This causes klect to use the {Bijous.defaultBundleName}, and bijous
# # to store results without a namespace
# bijous = new Bijous
#   bundles: 'modules/!(routes)'
#
# # We assume there is a module called *module1*
# bijous.load (err, modules) ->
#   console.log modules.module1
#
# # We define a new {Bijous} instance, specifying a bundle configuration with a
# # name. This causes klect to use a bundle name, and bijous to namespace the
# # results based on the bundle name
# bijous = new Bijous
#   bundles: { private: 'modules/!(routes)' }
#
# # We assume there is a module called *module1*
# bijous.load (err, modules) ->
#   console.log modules.private.module1
# ```
#
# Returns: `undefined`
setResult = (def, results, result) ->
  if def.bundle == @defaultBundleName then results[def.name] = result
  else _.merge results[def.bundle] ?= {}, _.object([def.name], [result])

  return

# Public: An asynchronous module loader. Searches out modules within a file
# system using [Klect](https://github.com/awnist/klect) and supplies an
# asynchronous means of initializing them.
#
# ## Module Definition
#
# Bijous modules are synonymous with klect bundles and can be retrieved and used
# in much the same ways. What bijous adds is the ability to `load` and `require`
# modules conforming to [node.js](http://nodejs.org/api/modules.html). Modules
# used in this way must conform to bijous' module interface which is described
# as a node module exporting a singular function with three arguments. The
# first argument will be the {Bijous} instance loading the module, the second
# argument will be an {Object} containing the results from previously loaded
# modules, and the third argument will be a {Function} callback that alerts the
# bijous instance when the module has completed loading. The callback function
# has two arguments, the first argument will be an {Error} if one has occurred,
# the second argument will be an optional {Object} containing pertinent results
# from loading the module, see {setResult}.
#
# ```coffee
# # We can assume that the following four lines describes the module being
# # loaded and resides in a file called *modules/mobule1.coffee*
# exports = module.exports = (context, modules, done) ->
#   # do something ...
#   done null,
#     app: express()
# ```
#
# ## Module Loading
#
# ```coffee
# # We can assume the rest of the code below lives in a separate file that
# # has access to the module specified above
# Bijous = require 'bijous'
#
# # Loads all modules
# bijous = new Bijous()
#
# bijous.load (err, modules) ->
#   # Access the results of module1
#   console.log modules.module1
#
# # Overrides the cwd option and loads all modules relative to it
# bijous = new Bijous
#   cwd: '~/modules'
#
# bijous.load (err, modules) ->
#   # Access the results of module1
#   console.log modules.module1
#
# # Overrides the bundles option and loads all modules accordingly
# bijous = new Bijous
#   bundles: 'modules/!(router)'
#
# bijous.load (modules) ->
#   # Access the results of module1
#   console.log modules.module1
#
# # Overrides the bundles option with multi bundles and loads all modules
# # one bundle's modules accordingly
# bijous = new Bijous
#   bundles:
#     server: 'modules/!(router)'
#     web: ['webModules/*', 'adminModules/*']
#
# bijous.load (err, modules) ->
#   # Access the results of module1, notice it is namespaced by the bundle
#   # name
#   console.log modules.server.module1
#   console.log modules.web.module2
# ```
class Bijous extends EventEmitter
  # Public: The default bundle configuration for klect as a {String}. This
  # configuration describes how all modules are to be found.
  # (default: `modules/*`). For more information see klect.
  @defaultBundles: 'modules/*'

  # Public: The default bundle name to pass to klect as a {String}. When a
  # bundle descriptor is passed from bijous to klect that is not an object
  # (e.g. a string or an array) this is the name used for the bundle. Bundle
  # results that bear it's name are not namespaced when received from the `load`
  # callback, see {setResult}. (default: `_`)
  @defaultBundleName: '_'

  # Public: Instantiates a new bijous loader.
  #
  # options - The hash {Object} used to configure bijous. (default: {})
  #           :cwd - The directory where modules can be found as a {String}.
  #                  Defaults to the directory the module's parent resides in.
  #                  (default: `path.dirname(module.parent.filename)`)
  #           :bundles - The klect bundles descriptor as an {Object}, used to
  #                      find modules. (default: {Bijous.defaultBundles})
  #           :defaultBundleName - The {String} name to use as the default
  #                                bundle for *klect*. When passing in a string
  #                                or an array for `bundles` this is the name
  #                                used as the bundle name. (default:
  #                                {Bijous.defaultBundleName})
  constructor: ({@cwd, @bundles, @defaultBundleName} = {}) ->
    @cwd ?= path.dirname module.parent.filename
    @bundles ?= Bijous.defaultBundles
    @defaultBundleName ?= Bijous.defaultBundleName

  # Public: Retrieves all modules found for it's bundles. When a bundle name is
  # supplied it retrieves files only for the specified bundle.
  #
  # bundle - The bundle name as a {String} to use when retrieving modules.
  #          (optional)
  #
  # ```coffee
  # Bijous = require 'bijous'
  #
  # # List all modules
  # bijous = new Bijous
  #   bundles:
  #     public: 'modules/public/*'
  #     private: 'modules/private/*'
  #
  # allBundles = bijous.list()
  # onlyPublicBundles = bijous.list 'public'
  # ```
  #
  # Returns an {Array} of klect bundles
  list: (bundle) ->
    klect = new Klect
      cwd: @cwd
      defaultBundleName: @defaultBundleName

    klect.gather(@bundles).bundles bundle

  # Public: Calls node's `require` function for all module files found for it's
  # bundles. When a bundle name is supplied it calls `require` with files
  # associated only with the specified bundle.
  #
  # bundle - The bundle name as a {String} to use when retrieving modules.
  # (optional)
  #
  # ```coffee
  # Bijous = require 'bijous'
  #
  # # Require all modules
  # bijous = new Bijous
  #   bundles:
  #     public: 'modules/public/*'
  #     private: 'modules/private/*'
  #
  # allBundles = bijous.require()
  # onlyPublicBundles = bijous.require 'public'
  # ```
  #
  # Returns an {Array} of {Object}s with the keys:
  #   :name - The module's name
  #   :bundle - The bundle's name
  #   :module - The module callback function as described in {Bijous}
  require: (bundle) ->
    _.flatten @list(bundle).map (asset) =>
      asset.files.map (file) =>
        name: getModuleName file
        bundle: asset.name
        module: require path.join(@cwd, file)

  # Public: Calls node's `require` function for all module files found for it's
  # bundles, and executes the returned module function. When a bundle name is
  # supplied it loads the files only for the specified bundle.
  #
  # bundle - The bundle name as a {String} to use when retrieving modules.
  #          (optional)
  # callback - The callback {Function} to use when all modules are loaded. The
  #            first argument will be an {Error} if one has occurred, the second
  #            will be the results of all loaded modules see {setResult}.
  #
  # ```coffee
  # Bijous = require 'bijous'
  #
  # # Loads all modules
  # bijous = new Bijous()
  # bijous.load()
  #
  # # Loads only modules belonging to the module1 bundle
  # bijous = new Bijous
  #   bundles:
  #     module1: ['modules/module1']
  #
  # bijous.load 'module1'
  #
  # # Loads all modules and executes a callback once all are loaded
  # bijous = new Bijous()
  #
  # bijous.load (error, results) ->
  #   throw error if error
  #   console.log results
  #
  # # Loads only modules belonging to the *module1* bundle and executes a
  # # callback once all are loaded
  # bijous = new Bijous
  #   bundles:
  #     bundle1: ['modules/module1']
  #
  # bijous.load 'bundle1', (error, modules) ->
  #   throw error if error
  #   console.log modules.bundle1.module1
  # ```
  #
  # Emits error if an error has occurred while loading any module. The first
  #   argument will be the {Error} that has occurred.
  #
  # Emits done when loading of modules has completed and no error has occurred.
  #   The first argument will be an {Object} containing the results of all
  #   loaded modules, see {setResult}. The `done` event could be subscribed to
  #   by the loaded module in order to execute a task once all modules are
  #   loaded. An example would be if a *server* module wanted to listen for
  #   connections once all modules were loaded.
  #
  # Returns `undefined`
  load: (bundle, callback) ->
    [callback, bundle] = [bundle, null] if 'function' == typeof bundle
    results = {}

    fns = @require(bundle).map (def) =>
      (done) => loadModule.call @, def, results, done

    async.series fns, (error) =>
      if callback then callback error, results

      if error and not callback then @emit 'error', error
      else if not error then @emit 'done', results

    return

exports = module.exports = Bijous
