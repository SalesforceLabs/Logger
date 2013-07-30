###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
express = require 'express'
gzippo = require 'gzippo'
routes = require './routes'
hogan = require 'hogan.js'
adapter = require './libs/server/hogan-express.js'
stylus = require 'stylus'
assetManager = require 'connect-assetmanager'
ScriptHelper = require './libs/server/ScriptHelper'
RedisStore = require('connect-redis')(express)

# Heroku redistogo connection
if process.env.REDISTOGO_URL
  rtg   = require('url').parse process.env.REDISTOGO_URL
  redis = require('redis').createClient rtg.port, rtg.hostname
  redis.auth rtg.auth.split(':')[1] # auth 1st part is username and 2nd is password devided by ":"
# Localhost
else
  redis = require("redis").createClient()

### Create express application (http://expressjs.com) ###
app = module.exports = express.createServer(
  express.cookieParser(),
  express.session
    secret: process.env.CLIENT_SECRET or "2636319206044415665"
    maxAge : new Date Date.now() + 7200000 # 2h Session timeout
    store: new RedisStore {client: redis}
  express.query()
)

### Configuration ###
jsFiles = ['localytics.js', 'jquery.1.7.1.min.js', 'hammer.js', 'jquery.hammer.js', 'spin.min.js', 'jquery.spin.js', 'iscroll.js', 'hogan-1.0.5.js']
coffeeFiles = ['L.coffee', 'LoggrUtil.coffee', "EventDispatcher.coffee", 'InvokeUrl.coffee', 'SFDC.coffee', 'Dialog.coffee', 'Platform.coffee', 'Config.coffee', 'BaseAction.coffee', 'Task.coffee', 'Note.coffee', 'Call.coffee', 'OpptyEdit.coffee', 'Edit.coffee', 'Model.coffee', 'UI.coffee', 'Search.coffee', 'Settings.coffee', 'Action.coffee', 'Panel.coffee', 'Detail.coffee', 'Main.coffee']
isProd = app.settings.env is 'production'
# uncomment to test production mode
# isProd = true
console.log 'isProd ' + isProd

app.configure ->
  console.log 'Dirname: ' + __dirname
  app.set 'views', __dirname + '/src/views'
  app.set 'view engine', 'hogan'
  app.use express.bodyParser()
  app.use express.csrf()
  app.use express.methodOverride()
  app.use app.router
  app.use assetManager ScriptHelper.config jsFiles
  app.use stylus.middleware
    src: __dirname
    dest: __dirname + '/public/'
    compile: (str, path) ->
      return stylus(str)
        .set('filename', path)
        .set('warn', true)
        .set('compress', isProd)
        .define('url', stylus.url({ paths: [__dirname + '/public'], limit:1000000 }))
    compress: isProd
    debug: !isProd
  app.use express.static __dirname + '/public'
  #app.use gzippo.staticGzip __dirname + '/public'
  #app.use gzippo.compress()
  app.dynamicHelpers
    # CSRF token, depends on express.csrf middleware
    token: (req, res) ->
      req.session._csrf
    script: (req, res) ->
      files = jsFiles.concat coffeeFiles
      scripts = ''
      scripts += ScriptHelper.scriptTag files, isProd
      return scripts
  app.register 'hogan', adapter.init(hogan)

app.configure 'development', ->
  app.use express.errorHandler({ dumpExceptions: true, showStack: true })

app.configure 'production', ->
  app.use express.errorHandler()


### Routes ###
app.get '/', routes.index
app.get '/urlschema', routes.urlschema
app.get '/manifest', routes.cache
app.get '/authenticate', routes.authenticate
app.get '/token', routes.token
app.get '/logout', routes.logout
app.get '/templates', routes.templates
app.post '/setSession', routes.setSession

apiVersion = "24.0"
getUrl = (endpoint) -> "/services/data/v#{apiVersion}/#{endpoint}"
app.get getUrl('search'), routes.search
app.get getUrl('query'), routes.query
app.get getUrl('sobjects'), routes.sobjects
app.post getUrl('sobjects/:type?'), routes.sobjects
app.get getUrl('sobjects/:type/:id?'), routes.sobjects
app.post getUrl('sobjects/:type/:id?'), routes.sobjects
app.post getUrl('chatter/feeds/:type/:id/feed-items'), routes.chatter
app.get getUrl('chatter/users/me'), routes.chatterUser

app.listen process.env.PORT or 4000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env
