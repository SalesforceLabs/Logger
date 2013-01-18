###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
superagent = require 'superagent'
restler = require 'restler'

class API

  @apiVersion = '24.0'

  ###
  @param oauth OAuth object used to sign request headers and to refresh expired SIDs.
  ###
  constructor: (@oauth) ->

  ###
  @param req Express request object
  @param sosl Salesforce Object Search Language (http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_calls_sosl_examples.htm)
  @param callback Callback function (err, result)
  ###
  search: (req, sosl, callback) ->
    action = 'search'
    @request req, 'GET', action, {q:sosl}, callback

  ###
  @param req Express request object
  @param soql Salesforce Object Query Language
  @param callback Callback function (err, result)
  ###
  query: (req, soql, callback) ->
    action = 'query'
    @request req, 'GET', action, {q:soql}, callback

  ###
  @param req Express request object
  @param sobjectType The specified value must be a valid object for your organization. For a complete list of objects, see Standard Objects.
  @param id Id of the record to be updated
  @param callback Callback function (err, result)
  ###
  get: (req, sobjectType, id, fields, callback) ->
    action = 'sobjects/'+ sobjectType
    if id
       action += '/' + id
       if fields?.length
         action += ('?fields=' + fields)
    @request req, 'GET', action, null, callback

  ###
  @param req Express request object
  @param sobjectType The specified value must be a valid object for your organization. For a complete list of objects, see Standard Objects.
  @param id Id of the record to be updated
  @param fields JSON object with fields to be updated
  @param callback Callback function (err, result)
  ###
  update: (req, sobjectType, id, fields, callback) ->
    action = 'sobjects/'+ sobjectType + '/' + id
    @request req, 'PATCH', action, fields, callback

  ###
  @param req Express request object
  @param sobjectType The specified value must be a valid object for your organization. For a complete list of objects, see Standard Objects.
         http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_objects_list.htm
  @param data JSON representation of the Task
  @param callback Callback function (err, result)
  ###
  create: (req, sobjectType, data, callback) ->
    action = 'sobjects/' + sobjectType
    @request req, 'POST', action, data, callback

  ###
  @param req Express request object
  @param data JSON with text and id
  @param callback Callback function (err, result)
  ###
  chatter: (req, resource, data, callback) ->
    action = 'chatter/feeds/'+resource+'/feed-items'
    console.log 'Chatter data: %s', JSON.stringify(data)
    url = req.session.instanceUrl + '/services/data/v' + API.apiVersion + '/' + action

    text = data.body.messageSegments[0].text
    restler.request url,
      method: 'POST'
      data: {text: text}
      headers:
          'Accept':'application/json'
          'Authorization':'OAuth ' + req.session.sid
          'Content-Type': 'application/json'
    .on 'complete', (data, response) ->
      callback null, data
    .on 'error', (data, response) ->
      callback data
    
    #@request req, 'POST', action, data, callback

  chatterUser: (req, callback) ->
    action = 'chatter/users/me'
    console.log 'Chatter action: %s', action
    url = req.session.instanceUrl + '/services/data/v' + API.apiVersion + '/' + action

    restler.request url,
      method: 'GET'
      headers:
          'Accept':'application/json'
          'Authorization':'OAuth ' + req.session.sid
          'Content-Type': 'application/json'
    .on 'complete', (data, response) ->
      callback null, data
    .on 'error', (data, response) ->
      callback data
    

  ###
  @param req Express request object
  @param method URL request method
  @param action Rest action
  @param data Optional data object which will be added to the request
  @param callback Callback function (err, result)
  @param isRetry Boolean flag only used internally. Used to retry a call after a SID has been refreshed
  ###
  request: (req, method, action, data, callback, isRetry = false) ->
    url = req.session.instanceUrl + '/services/data/v' + API.apiVersion + '/' + action
    console.log 'request ' + method + ': ' + url + ' -> ' + JSON.stringify data
    

    header =
      'Accept': 'application/json'
      'Authorization': 'OAuth ' + req.session.sid
      'Content-Type': 'application/json'

    self = this
    superagent(method, url)
      .send(data)
      .set(header)
      .end (response) ->
        #console.log 'raw ' + JSON.stringify response.headers
        console.log 'request ' + method + ': ' + url + ' -> ' + response.statusCode
        if response.statusCode >= 200 and response.statusCode < 300
          callback null, response.body
        else
          console.log "Error: " + response.text

          if response.statusCode is 401
            if !isRetry && req.session.refreshToken
              self.oauth.refresh req, (response) ->
                if response.success
                  console.log 'Got new SID. Trying to execute request again.'
                  self.request req, method, action, data, callback, true
                else 
                  callback response.error
            else
              console.log 'Retry with new SID failed again. Giving up.'
              callback {text: response.text, statusCode: response.statusCode}
          else
            callback {text: response.text, statusCode: response.statusCode}

module.exports = API