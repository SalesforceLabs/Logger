###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

OAuth = require '../libs/server/OAuth'
API = require '../libs/server/API'
HoganTemplate = require '../libs/server/HoganTemplate'

port = process.env.PORT or 4000
cid = process.env.LOGGER_WEB_CONSUMER_KEY
csecr = process.env.LOGGER_WEB_CONSUMER_SECRET
lserv = process.env.LOGIN_SERVER or 'https://login.salesforce.com'
redir = process.env.REDIRECT_URI or 'http://localhost:' + port + '/token'

if not process.env.LOGGER_WEB_CONSUMER_KEY or not process.env.LOGGER_WEB_CONSUMER_SECRET
  console.error "environment var for LOGGER_WEB_CONSUMER_KEY and/or LOGGER_WEB_CONSUMER_SECRET not set"
  return

oauth = new OAuth
  clientId: cid
  clientSecret: csecr
  loginServer: lserv
  redirectUri: redir

api = new API oauth

exports.index = (req, res) ->
  console.log 'hitting index.'
  # Avoid Clickjacking
  res.header 'X-FRAME-OPTIONS', 'deny'
  # HTTP Strict Transport Security
  res.header 'Strict-Transport-Security', 'max-age=15768000; includeSubDomains'
  res.render 'index', {title: 'Sales Logger'}

exports.urlschema = (req, res) ->
  link = "<a href='loggr://x-callback-url/task?id=0033000001CfIWWAA3&type=Checkin&text=foo%20bar&x-cancel=foo://bar&x-success=bar://foo'>Open Loggr</a>"
  res.send link

exports.cache = (req, res) ->
  res.header 'Content-Type', 'text/cache-manifest'
  res.render '', layout: 'cache'

exports.authenticate = (req, res) ->
  hasLoggedOut = req.session.hasLoggedOut?
  console.log 'authenticate (hasLoggedOut: %s)', hasLoggedOut
  res.redirect oauth.loginUrl hasLoggedOut
  req.session.hasLoggedOut = false

# OAuth redirect Url
exports.token = (req, res) ->
  oauth.codeHandler req, (response) ->
    if response.success
      res.redirect '/?auth=true'
    else
      console.error response
      res.send response.statusCode || 400

exports.setSession = (req, res) ->
  console.log 'setting session values: ' + req.body.access_token + ', ' + req.body.instance_url
  req.session.sid = req.body.access_token
  req.session.instanceUrl = req.body.instance_url
  res.send 200

exports.logout = (req, res) ->
  console.log 'trigger logout'
  oauth.logout req, (response) ->
    if response.error
      console.error response.error
    req.session.hasLoggedOut = true if response.success
    res.send JSON.stringify response

exports.chatter = (req, res) ->
  if req.session.sid
    type = req.params.type
    id = req.params.id
    resource = type + "/" + id
    console.log "JSON " + JSON.stringify(req.body)
    api.chatter req, resource, req.body, (err, result) ->
      if err
        console.log 'Error post on Chatter: %s' + err
        res.status err.statusCode
        res.send err.text
      else
        json = JSON.stringify result
        console.log 'posted on chatter: %s', json
        res.contentType 'application/json'
        res.send json
  else
    console.error 'No Session ID present.'
    res.send 401

exports.chatterUser = (req, res) ->
  if req.session.sid
    api.chatterUser req, (err, result) ->
      if err
        console.log 'Error get user on Chatter:' + err
        res.send err
      else
        json = JSON.stringify result
        #console.log 'got user on chatter: %s', json
        res.contentType 'application/json'
        res.send json
  else
    console.error 'No Session ID present.'
    res.send 401

exports.sobjects = (req, res) ->
  type = req.params.type
  id = req.params.id

  ###
  trigger.io Container code
  if not req.session.sid and req.query.sid?
    req.session.sid = req.query.sid
    req.session.instanceUrl = 'https://na1.salesforce.com'
  ###

  if req.session.sid
    
    console.log if id then 'load detail ' + id else 'get list'
    
    # delete csrf token after validation when present
    # otherwise you get for instance this kind of Error: [{"message":"No such column '_csrf' on sobject of type Note","errorCode":"INVALID_FIELD"}]
    delete req.body._csrf if req.method is 'POST' and req.body
    
    if id
      switch req.method
        when 'GET'
          start = new Date().getTime()
          api.get req, type, id, req.query.fields, (err, result) ->
            ms = new Date().getTime() - start
            #console.log '###PERFORMANCE### Took %d ms to load %s', ms, type
            if err
              console.error err
              res.send err.statusCode
            else 
              json = JSON.stringify result
              #console.log "got detail " + json
              res.contentType 'application/json'
              res.send json
        # This should be PATCH or PUT which doesn't work right now.
        when 'POST'
          console.log 'POST (update in this case)'
          api.update req, type, id, req.body, (err, result) ->
            if err
              console.error err
              res.status err.statusCode
              res.send err.text
            else
              json = JSON.stringify result
              console.log "updated detail " + json
              res.contentType 'application/json'
              res.send json
        else
          console.error 'Unsupported method ' + req.method
          res.send 400
    else if type
      switch req.method
        when 'GET'
          start = new Date().getTime()
          api.get req, type, null, null, (err, result) ->
            ms = new Date().getTime() - start
            #console.log '###PERFORMANCE### Took %d ms to load recent %s', ms, type
            if err
              console.log 'Failed to load contacts: ' + err
              res.send err.statusCode
            else
              json = JSON.stringify result
              res.contentType 'application/json'
              res.send json
        when 'POST'
          api.create req, type, req.body, (err, result) ->
            if err
              console.error err
              res.status err.statusCode
              res.send err.text
            else
              json = JSON.stringify result
              console.log "created " + type + ' -> ' + json
              res.contentType 'application/json'
              res.send json
        else
          console.error 'Unsupported method ' + req.method
          res.send 400
    else
      switch req.method
        when 'GET'
          api.get req, '', null, null, (err, result) ->
            ms = new Date().getTime() - start
            console.log 'Describe Gobal'
            if err
              console.log 'Failed to describe global: ' + err
              res.send err.statusCode
            else
              json = JSON.stringify result
              res.contentType 'application/json'
              res.send json
        else
          console.error 'Unsupported method ' + req.method
          res.send 400

  else
    console.error 'No Session ID present for /sobjects/%s/%s', type, id
    res.send 401

exports.query = (req, res) ->
  if req.session.sid
    console.log "query " + req.query['q']
    soql = req.query['q']

    api.query req, soql, (err, result) ->
      if err
        console.log 'Failed query: ' + err
        res.send err.statusCode || 400
      else
        json = JSON.stringify result
        console.log 'query result ' + json
        res.contentType 'application/json'
        res.send json
  else
    console.error 'No Session ID present.'
    res.send 401

exports.search = (req, res) ->
  if req.session.sid
    sosq = req.query['q']
    console.log "search " + sosq
    api.search req, sosq, (err, result) ->
      if err
        console.log 'Failed to search: ' + err
        res.send err.statusCode || 400
      else
        json = JSON.stringify result
        console.log 'search result ' + json
        res.contentType 'application/json'
        res.send json
  else
    console.error 'No Session ID present.'
    res.send 401

# The templates route generates the JavaScript file
# for the server side compiled Hogan templates.
# Include it like: <script src='templates' type='text/javascript'></script>
# Templates are in the T namespace and can be renderered like
# contactsList = new Hogan.Template(T.contacts)
# $('#content').append(contactsList.render {contacts:contacts})
exports.templates = (req, res) ->
  a = ['list', 'dialog', 'drill_down', 'related_list', 'detail', 'actions', 'search', 'search_result', 'settings', 'task', 'note', 'add', 'home', 'pending', 'eula_ios', 'about', 'settings_modal', 'call', 'opportunity_select', 'oppty_edit']
  HoganTemplate.load req, res, __dirname + '/../src/templates/', a
