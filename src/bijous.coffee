path = require 'path'
util = require 'util'
series = require 'array-series'
_ = require 'lodash'
parameterize = require 'parameterize'
camelize = require 'camelize'
{EventEmitter} = require 'events'
Klect = require 'klect'

# Private: Determines a module's name
#
# file - The path of a file as a {String}
#
# Returns: A {String} representing the module's name
getModuleName = (file) ->
  extname = path.extname file
  camelize parameterize path.basename(file, extname)

# Private: Loads a singular module as described by {Bijous}. Handles populating
# the module's service object if it provides one.
#
# def      - The module's definition {Object} with the following keys:
#            :name - The module's name
#            :bundle - The bundle's name
#            :module - The module's load function
# services - The services returned by any previously loaded modules as an
#            {Object}. The definition of this object can be found in
#            {.setService}.
# done     - Callback {Function} that alerts {Bijous} when the module has
#            loaded, the first argument will be an {Error} if one has occurred.
#
# Returns: `undefined`
loadModule = (def, services, done) ->
  # console.log def.module.length
  isAsync = def.module.length > 2
  moduleDone = (error, service) =>
    setService.call(this, def, services, service) if service

    @emit 'loaded', def.name, def.bundle, services unless error
    done error

  if isAsync
    def.module.call null, @, services, moduleDone
  else
    def.module.call null, @, services
    moduleDone()

  return

# Private: A helper function that adds a module's service to the collection of
# services returned by loading all modules.
#
# def      - The module's definition {Object} with the following keys:
#            :name - The module's name
#            :bundle - The bundle's name
#            :module - The module's load function
# services - The services returned by any previously loaded modules as an
#            {Object}. The definition of this object can be found in {Bijous}.
# service  - The service {Object} the loaded module provides.
#
# Returns: `undefined`
setService = (def, services, service) ->
  if def.bundle is @defaultBundleName then services[def.name] = service
  else _.merge services[def.bundle] ?= {}, _.object([def.name], [service])

  return

# Public: An asynchronous module loader. Searches out modules within a file
# system using [Klect](https://github.com/awnist/klect) and supplies an
# asynchronous means of initializing them. Initialized modules may provide a
# service that can be used by other modules and is made available to external
# code after loading has completed.
#
# ## Module Definition
#
# Bijous modules are synonymous with Klect bundles and can be retrieved and used
# in much the same way. What Bijous adds is the ability to `load` and `require`
# modules conforming to the [node.js](http://nodejs.org/api/modules.html)
# module specification. Modules used in this way must conform to Bijous' module
# interface.
#
# ### Bijous Module Interface
#
# A Bijous module is a node module that exports a single function with three
# arguments. The first argument will be the {Bijous} instance loading the
# module, the second argument will be an {Object} containing the services
# previously loaded modules provide, and the third argument will be a {Function}
# callback that alerts the {Bijous} instance when the module has completed
# loading. The callback function has two arguments, the first argument will be
# an {Error} if one has occurred, the second argument will be an optional
# {Object} containing provided services from all loaded modules.
#
# #### Service Object Naming
#
# The service object provides accessor properties corresponding to their module
# name and namespaced by their bundle name.
#
# ##### Module Names
#
# The module's name is the name of it's file without the path and extension
# passed as an argument to both `parameterize` and `camelize`.
#
# ##### Bundle Name and Namespacing
#
# If the bundle's name happens to match the defaultBundleName
# (see {Bijous::constructor}), the service will *not* use namespacing and
# instead apply the accessor property directly to the service object.
#
# ###### Default Bundles Have No Namespace
#
# You would create a bundle with a default name by not passing in a `bundles`
# option to {Bijous::constructor} or by passing in either a {String} or an
# {Array} as the `bundles` option to the {Bijous} constructor.
#
# ```coffee
# Bijous = require 'bijous'
#
# # We define a new {Bijous} instance without passing in a `bundles` option.
# # This causes Klect to use the `defaultBundleName`, and Bijous to
# # store services without a namespace
# bijous = new Bijous()
#
# # We assume there is a module called *module1*
# bijous.load (err, modules) -> console.log modules.module1
#
# # We define a new {Bijous} instance by supplying only a {String} as the
# # `bundles` option. This causes Klect to use the `defaultBundleName`,
# # and Bijous to store services without a namespace
# bijous = new Bijous { bundles: 'modules/!(routes)' }
#
# # We assume there is a module called *module1*
# bijous.load (err, modules) -> console.log modules.module1
# ```
#
# ###### Specified Bundle Names Have Namespace
#
# You would create a bundle with a custom name by passing in an {Object}
# definition as the `bundles` option to {Bijous::constructor}.
#
# ```coffee
# # We define a new {Bijous} instance by supplying an {Object} as the `bundles`
# # option. This causes Klect to use a bundle name, and Bijous to namespace the
# # services based on the bundle name
# bijous = new Bijous { bundles: { private: 'modules/!(routes)' } }
#
# # We assume there is a module called *module1*
# bijous.load (err, modules) -> console.log modules.private.module1
# ```
#
# ## Example
#
# We can assume that the following code describes the module being loaded,
# resides in a file called *modules/mobule1.coffee*, and provides a service
# containing a pointer to an express app.
#
# ```coffee
# exports = module.exports = (context, modules, done) ->
#   # do something ...
#   done null, { app: express() }
# ```
#
# ## Module Loading
#
# We can assume the rest of the code below lives in a separate file that has
# access to the module specified above.
#
# ```coffee
# Bijous = require 'bijous'
#
# bijous = new Bijous()
#
# # Access the module1 service after it's been loaded
# bijous.load (err, modules) -> console.log modules.module1
#
# # Overrides the `cwd` option and loads all modules relative to it
# bijous = new Bijous { cwd: '~/modules' }
#
# # Access the module1 service after it's been loaded
# bijous.load (err, modules) -> console.log modules.module1
#
# # Overrides the `bundles` option and loads all modules accordingly
# bijous = new Bijous { bundles: 'modules/!(router)' }
#
# # Access the module1 service after it's been loaded
# bijous.load (modules) -> console.log modules.module1
#
# # Overrides the `bundles` option with multiple bundles and loads all modules
# bijous = new Bijous
#   bundles:
#     server: 'modules/!(router)'
#     web: ['webModules/*', 'adminModules/*']
#
# # Access the module1 service, namespaced by the bundle name
# bijous.load (err, modules) ->
#   console.log modules.server.module1
#   console.log modules.web.module2
# ```
class Bijous extends EventEmitter
  # Internal: The default bundle configuration for Klect as a {String}.
  @defaultBundles: 'modules/*'

  # Internal: The default bundle name to pass to Klect as a {String}.
  @defaultBundleName: '_'

  # Public: Instantiates a new {Bijous} loader.
  #
  # options - The hash {Object} used to configure {Bijous}. (default: {})
  #           :cwd - The directory where modules can be found as a {String}.
  #                  Defaults to the directory the module's parent resides in.
  #                  (default: `path.dirname(module.parent.filename)`)
  #           :bundles - The Klect bundles descriptor as an {Object}, {Array},
  #                      or {String}. Describes the pattern to use when locating
  #                      module files, is appended to `cwd`. For more details,
  #                      see [Klect](https://github.com/awnist/klect).
  #                      (default: 'modules/*')
  #           :defaultBundleName - The {String} to use as the default bundle
  #                                name for
  #                                [Klect](https://github.com/awnist/klect).
  #                                Bundles bearing this name will not namespace
  #                                it's provided services, see {Bijous}.
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
  #     bundles:
  #       public: 'modules/public/*'
  #       private: 'modules/private/*'
  #
  # allBundles = bijous.list()
  # onlyPublicBundles = bijous.list 'public'
  # ```
  #
  # Returns an {Array} of Klect bundles
  list: (bundle) ->
    klect = new Klect
      cwd: @cwd
      defaultBundleName: @defaultBundleName

    klect.gather(@bundles).bundles bundle

  # Public: Calls node's `require` function for all module files found for it's
  # bundles. When a bundle name or pattern is supplied it calls `require` with
  # files associated only with the specified bundles.
  #
  # bundle - The bundle name or pattern as a {String} to use when retrieving
  # modules. (optional)
  #
  # ```coffee
  # Bijous = require 'bijous'
  #
  # # Require all modules
  # bijous = new Bijous
  #     bundles:
  #       public: 'modules/public/*'
  #       private: 'modules/private/*'
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
  # bundles, and executes the returned module function. When a bundle name or
  # pattern is supplied it loads the files associated only with the specified
  # bundles.
  #
  # bundle   - The bundle name or pattern as a {String} to use when retrieving
  #            modules. (optional)
  # callback - The callback {Function} to use when all modules are loaded. The
  #            first argument will be an {Error} if one has occurred, the second
  #            will be the services of any loaded modules that provide them,
  #            see {Bijous}.
  #
  # ```coffee
  # Bijous = require 'bijous'
  #
  # # Loads all modules
  # bijous = new Bijous()
  # bijous.load()
  #
  # # Loads only modules belonging to the module1 bundle
  # bijous = new Bijous { bundles: { module1: ['modules/module1'] } }
  # bijous.load 'module1'
  #
  # # Loads all modules and executes a callback once all are loaded
  # bijous = new Bijous()
  # bijous.load (error, services) ->
  #     throw error if error
  #     console.log services
  #
  # # Loads only modules belonging to the module1 bundle and executes a
  # # callback once all are loaded
  # bijous = new Bijous { bundles: { bundle1: ['modules/module1'] } }
  # bijous.load 'bundle1', (error, modules) ->
  #     throw error if error
  #     console.log modules.bundle1.module1
  # ```
  #
  # Emits `error` if an error has occurred while loading any module and no
  #   callback argument has been supplied. The first argument will be the
  #   {Error} that has occurred.
  #
  # Emits `loaded` when a module has successfully loaded. The first argument
  #   will be a {String} representing the module's name; the second argument
  #   will be a {String} representing the bundle's name; the third, optional
  #   argument will be an {Object} representing any services the module
  #   provides.
  #
  # Emits `done` when loading of all modules has completed and no error has
  #   occurred. The first argument will be an {Object} containing the services
  #   of any loaded modules that supply them, see {Bijous}. The `done` event
  #   could be subscribed to by the loading modules in order to execute a task
  #   once all modules are loaded. An example would be if a *server* module
  #   wanted to listen for connections once all modules were loaded.
  #
  # ```coffee
  # exports = module.exports = (context, modules, done) ->
  #     app = express()
  #     context.on 'done', ->
  #       app.listen 3000, -> console.log 'Listening on port 3000'
  #     done null, { app: app }
  # ```
  #
  # Returns `undefined`
  load: (bundle, callback) ->
    [callback, bundle] = [bundle, null] if 'function' is typeof bundle
    services = {}

    fns = @require(bundle).map (def) =>
      (done) => loadModule.call @, def, services, done

    series fns, (error) =>
      if callback then callback error, services

      if error and not callback then @emit 'error', error
      else if not error then @emit 'done', services

    return

exports = module.exports = Bijous
