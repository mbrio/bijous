path = require 'path'
util = require 'util'
async = require 'async'
_ = require 'lodash'
{EventEmitter} = require 'events'
Klect = require 'klect'

# Internal: Gets a module's name based off of it's path.
#
# file - The path of the file as {String}
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

# Internal: Loads a singular module. Handles populating the module's result
# object. Emits the `loaded` event when a module is successfully loaded. The
# `loaded` event handler receives three parameters, the module's name, the
# bundle's name, and the module's results.
#
# Returns nothing
loadModule = (def, results, done) ->
  def.module.call null, @, results, (error, result) =>
    if result
      if def.bundle == @defaultBundleName then results[def.name] = result
      else _.merge results[def.bundle] ?= {}, _.object([def.name], [result])

    @emit 'loaded', def.name, def.bundle, results unless error
    done error

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
# as a node module exporting a singular function that receives three parameters
# corresponding to the `bijous` object loading the module, the currently
# returned `results` from previously loaded modules, and the `callback` that
# alerts bijous that the module has completed loading. The `callback` function
# receives two parameters that correspond to any errors that have
# occurred, and can optionally return an object that represents the result of
# the module.
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
# bijous = new Bijous
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
  # Public: The default bundle configuration for klect. This configuration
  # describes how all modules are to be found. (default: `modules/*`).
  @defaultBundles: 'modules/*'

  # Public: The default bundle name to pass to klect. When a bundle descriptor
  # is passed from bijous to klect that is not an object (e.g. a string or
  # an array) this is the name that is used for the bundle. Bundle results that
  # bear it's name are not namespaced when received from the `load` callback.
  # (default: `_`)
  #
  # ```coffee
  # Bijous = require 'bijous'
  #
  # bijous = new Bijous
  #   bundles: 'modules/!(router)'
  #
  # bijous.load (err, modules) ->
  #   # Since our bundle does not have a name the default bundle name is used
  #   # and it's results are not namespaced
  #   console.log modules.module1
  # ```
  @defaultBundleName: '_'

  # Public: Instantiates a new bijous loader.
  #
  # options - The hash options used to configure bijous. (default: {})
  #           :cwd - The directory where modules can be found. Defaults to the
  #                  directory the module's parent resides in.
  #                  (default: `path.dirname(module.parent.filename)`)
  #           :bundles - The klect bundles descriptor, used to find modules.
  #                      (default: `Bijous.defaultBundles`)
  #           :defaultBundleName - The name to use as the default bundle for
  #                                *klect*. When passing in a string or an array
  #                                for `bundles` this is the name used as the
  #                                bundle name. (default:
  #                                `Bijous.defaultBundleName`)
  constructor: ({@cwd, @bundles, @defaultBundleName} = {}) ->
    @cwd ?= path.dirname module.parent.filename
    @bundles ?= Bijous.defaultBundles
    @defaultBundleName ?= Bijous.defaultBundleName

  # Public: Retrieves all modules found for it's bundles. When a bundle name is
  # supplied it only retrieves files for the specified bundle.
  #
  # bundle - The bundle name to use when retrieving modules. (optional)
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
  # Returns an array of klect bundles
  list: (bundle) ->
    klect = new Klect
      cwd: @cwd
      defaultBundleName: @defaultBundleName

    klect.gather(@bundles).bundles bundle

  # Public: Calls node's `require` function for all module files found for it's
  # bundles. When a bundle name is supplied it only calls `require` with files
  # for the specified bundle.
  #
  # bundle - The bundle name to use when retrieving modules. (optional)
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
  # Returns the modules exported by calling `require` on each of the bundle
  #   files; each module object contains a module's `name`, the corresponding
  #   bundle's name, and the `module` returned by calling node's `require`
  #   function on the module's file.
  require: (bundle) ->
    _.flatten @list(bundle).map (asset) =>
      asset.files.map (file) =>
        name: getModuleName file
        bundle: asset.name
        module: require path.join(@cwd, file)

  # Public: Calls node's `require` function for all module files found for it's
  # bundles, and executes the returned module function. When a bundle name is
  # supplied it only loads the files for the specified bundle. Once all bundles
  # are loaded bijous will emit either an `error` event, if any have occurred,
  # or a `done` event which receives the results of all the modules.
  #
  # The `done` event could be subscribed to by the loaded module in order to
  # execute a task once all modules are loaded. An example would be for a
  # *server* module that creates an express web server to startup once all
  # modules are loaded.
  #
  # bundle - The bundle name to use when retrieving modules. (optional)
  # callback - The callback function to use when all modules are loaded. The
  #            `callback` receives two parameters, the first corresponds to any
  #            errors that have occurred, the second contains the results of all
  #            of the loaded modules.
  #
  # ```atom
  # Bijous = require 'bijous'
  #
  # # Loads all modules
  # bijous = new Bijous
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
  # bijous = new Bijous
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
  # Returns nothing
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
