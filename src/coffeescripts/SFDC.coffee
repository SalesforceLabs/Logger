###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
# Service class to access the Force.com and Connect API
class SFDC

  # Count of pending API calls
  @activityCount = 0

  # Storage for the previous error  
  # In same cases we need to know the previous for better error handling
  # like the session timeout after being offline interrupted.
  @previousError

  # Contact Constant
  @CONTACT = 'Contact'

  # Account Constant
  @ACCOUNT = 'Account'

  # Opportunity Constant
  @OPPORTUNITY = 'Opportunity'

  # Lead Constant
  @LEAD = 'Lead'

  # Threshold in ms when an ajax call is considered to be timed out.
  @_TIMEOUT_THRESHOLD = 30000

  # Min time in ms to wait before retrying a request.
  @_MIN_WAIT_TIME = 2500

  # SFDC API Version
  @apiVersion = '24.0'

  # _private_ Session Id
  @_sid = ''

  # _private_ Instance Url
  @_instanceUrl = ''


  # Flag if app is in the container (Cordova PhoneGap)
  @isContainer = false

  @authenticator = null

  # Property to track if a valid session id is set for making API calls
  @sessionAlive = false

  # Property to track whether we are queueing failed requests or not.
  @allowRequestQueueing = false

  # Property to queue requests queueing after session expiration. Only done inside container.
  @requestQueue = []

  # Set the session Id for container usage.  
  # `sid` Session Id
  @setSID: (sid) -> SFDC._sid = sid

  # Marks the SFDC API caller as ready to make API calls.  
  # No API call will be tried until this is marked as ready.  
  # `isReady` true/false
  @setReady: (isReady) ->
    SFDC.sessionAlive = isReady
    # If the session is active, execute any old queued up requests
    SFDC.replayQueue()

  # Replay service queue
  @replayQueue: ->
    isOnline = true
    if SFHybridApp?
      isOnline = SFHybridApp.deviceIsOnline()
    if SFDC.sessionAlive and isOnline and SFDC.allowRequestQueueing and SFDC.requestQueue.length
      # execute each method in the queue
      SFDC.requestQueue.forEach (requestRetry) ->
        requestRetry()
      # mark the queue as empty
      SFDC.requestQueue = []

  # `instanceUrl` Instance Url like https://na1.salesforce.com.
  @setInstanceUrl: (instanceUrl) -> SFDC._instanceUrl = instanceUrl

  # `isContainer` Flag if client is inside a container.
  @setContainer: (isContainer) ->
    LoggrUtil.log 'isContainer: ' + isContainer
    SFDC.isContainer = isContainer
    SFDC.allowRequestQueueing = true

  # `authenticatorFn` Method to refreshSession on session expiration.
  @setAuthenticator: (authenticatorFn) ->
    LoggrUtil.log 'setting authenticator function'
    SFDC.authenticator = authenticatorFn

  # _private_ method to retrieve the base service Url
  @_getBaseUrl: () -> "/services/data/v#{SFDC.apiVersion}/"

  # `callback` Callback function after logout is complete.
  @logout: (callback) ->
    LoggrUtil.log 'logout isContainer? ' + SFDC.isContainer
    if SFDC.isContainer
      SFDC.setSID ''
      SFDC.setInstanceUrl ''
      callback null
    else
      $.getJSON SFDC._instanceUrl + '/logout', (data) ->
        callback data

  # Loads a list of MRUs  
  # `sobjectType` Name of the Salesforce object. E.g. 'Contact' or 'Account'  
  # `id` Optional Id of the record or null to get MRUs  
  # `fields` Optional Fields to query  
  # `callback` Callback function (err, data)  
  @get: (sobjectType, id, fields, callback) ->
    url = "sobjects/#{sobjectType}"
    # Add id if a specific resource is requested.
    if id?
      url += '/' + id
      if fields?.length
        data = ('fields=' + fields)

    SFDC.ajax url, 'GET', data,  callback

  # `sobjectType`  
  # `data`  
  # `callback` Callback function (err, result)
  @create: (sobjectType, data, callback) ->
    # Add CSRF token for web-app
    if not SFDC.isContainer
      data._csrf = $('#csrf_token').attr('value')

    payloadJSON = JSON.stringify data

    SFDC.ajax "sobjects/#{sobjectType}", 'POST', payloadJSON, callback

  # `sobjectType` The specified value must be a valid object for your organization. For a complete list of objects, see Standard Objects.  
  # `json` JSON of the record to be updated  
  # `fields` JSON object with fields to be updated  
  # `callback` Callback function (err, result)
  @update: (sobjectType, json, fields, callback) ->
    type = 'PATCH'

    # Add CSRF token for web-app
    if not SFDC.isContainer
      fields._csrf = $('#csrf_token').attr('value')
      # Heroku does not support PATCH so we use POST as a workaround
      type = 'POST'
    
    payloadJSON = JSON.stringify fields
    url = "sobjects/#{sobjectType}/#{json.Id}"
    SFDC.ajax url, type, payloadJSON, callback

  # `accountId` Id of the account to find related contacts on  
  # `callback` Callback function (err, data)
  @getRelated: (relatedObject, accountId, callback) ->
    LoggrUtil.log "getRelated"
    soql = "SELECT Id, Name FROM #{relatedObject}
            WHERE Account.Id = '#{accountId}' ORDER BY Name"

    SFDC.query soql, callback

  # `accountId` Id of the account to count the related contacts on  
  # `callback` Callback function (err, data)
  @getRelatedCount: (relatedObject, accountId, callback) ->
    LoggrUtil.log "getRelatedCount"
    soql = "SELECT COUNT() FROM #{relatedObject} WHERE Account.Id = '#{accountId}'"
    SFDC.query soql, callback

  # Helper function to quote IDs  
  # `ids` Array of IDs
  @quoteIds: (ids) ->
    addQuotes = (id) -> return "'#{id}'"
    ids = (addQuotes id for id in ids)

  # `accountIds` Array of account Ids
  @getAccountNameQuery: (accountIds) ->
    accountIds = SFDC.quoteIds accountIds
    "SELECT Id, Name FROM Account WHERE Account.Id IN (#{accountIds})"

  # `accountIds` Array of account IDs  
  # `callback` Callback function (err, result)
  @getAccountNames: (accountIds, callback) ->
    LoggrUtil.log "getAccountNames"
    soql = SFDC.getAccountNameQuery accountIds
    SFDC.query soql, callback

  # Query related opportunites  
  # `accountId` Filter opportunities by account  
  # `callback` Callback function (err, data)
  @opportunities: (accountId, callback) ->
    LoggrUtil.log "get opportunities"
    soql = "SELECT Id, Name
            FROM Opportunity
            WHERE IsClosed=false AND AccountId='#{accountId}' ORDER BY LastActivityDate"

    SFDC.query soql, callback

  # SOQL Query
  # `accountId` Filter opportunities by account  
  # `callback` Callback function (err, data)
  @query: (soql, callback) ->
    SFDC.ajax "query", 'GET', {q:soql}, callback

  # `searchTerm` Search term
  # `config` Dictonary for Contact/Accounts?opportunity/Leads configuration  
  # `callback` Callback function (err, data)
  @search: (searchTerm, config, callback) ->
    if searchTerm? and searchTerm.length >= 2
      searchTerm = searchTerm.replace /([\?&|!{}\[\]\(\)\^~\*:\\"'+-])/g, '\\$1'
      sosq = 'FIND { ' + searchTerm + '* }
              IN Name Fields
              RETURNING '

      obj = ''
      if config[SFDC.CONTACT]? and config[SFDC.CONTACT]
        obj += ',' if obj isnt ''
        obj += ' contact(name, id'
        if Config.isFieldVisible SFDC.CONTACT, "AccountId"
          obj += ', accountid'
        obj += ')'

      if config[SFDC.ACCOUNT]? and config[SFDC.ACCOUNT]
        obj += ',' if obj isnt ''
        obj += ' account(name, id)'

      if config[SFDC.OPPORTUNITY]? and config[SFDC.OPPORTUNITY]
        obj += ',' if obj isnt ''
        obj += ' opportunity(name, id'
        if Config.isFieldVisible SFDC.OPPORTUNITY, "AccountId"
          obj += ', accountid'
        obj += ')'

      if config[SFDC.LEAD]? and config[SFDC.LEAD]
        obj += ',' if obj isnt ''
        obj += ' lead(name, id)'

      sosq += obj

      LoggrUtil.log 'Search: ' + sosq

      SFDC.ajax "search", 'GET', {q:sosq}, callback
    else
      callback {status: 400}

  # `data` JSON with text and id  
  # `callback` Callback function (err, result)
  @chatter: (resource, text, callback) ->
    data = {body: {messageSegments: [{type: 'Text',text : text}]}}
    
    # Add CSRF token for web-app
    if not SFDC.isContainer
      data._csrf = $('#csrf_token').attr('value')

    payloadJSON = JSON.stringify data

    url = "chatter/feeds/#{resource}/feed-items"
    SFDC.ajax url, 'POST', payloadJSON, callback

  # Get Chatter user  
  # `callback` Callback function (err, result)
  @chatterUser: (callback) ->
    SFDC.ajax 'chatter/users/me', 'GET', null, callback

  # `url` Url to request  
  # `type` GET, POST, PATCH  
  # `data`  
  # `callback` Callback function (err, data)  
  # `ignoreRetry` Flag if the call is allowed to retry when failed
  @ajax: (url, type, data, callback) ->
    serverUrl = SFDC._instanceUrl + SFDC._getBaseUrl()
    if url.indexOf(serverUrl) isnt 0
      url = serverUrl + url

    LoggrUtil.log "ajax #{type}:" + url

    getXHRConfig = (failOnError) ->
      url: url
      type: type
      data: data
      timeout: SFDC._TIMEOUT_THRESHOLD
      contentType: 'application/json; charset=utf-8'
      dataType: 'json'
      beforeSend: (xhr) ->
        SFDC.activityCount++
        Platform.showStatusBarActivityIndicator()
        if SFDC.isContainer
          xhr.setRequestHeader 'Accept', 'application/json'
          xhr.setRequestHeader 'Authorization', 'OAuth ' + SFDC._sid
      complete: () ->
        if --SFDC.activityCount is 0
          Platform.hideStatusBarActivityIndicator()
      success: (data) ->
        callback null, data
      error: (err, textStatus, errorThrown) ->
        LoggrUtil.log "AJAX error #{JSON.stringify(err)}"

        # check if it was a retry with same previous error
        if err.status is failOnError
          if err.status is 0
            LoggrUtil.logConnectionError()
            callback err, null
          else
            SFDC.showCustomError err, ->
              callback err, null
        # else if request just failed to connect to network, try again in @_MIN_WAIT_TIME
        else if err.status is 0
          LoggrUtil.log "Status 0. Retry in #{SFDC._MIN_WAIT_TIME}ms"
          setTimeout ->
            retryFn(0)()
          , SFDC._MIN_WAIT_TIME
        # else if request failed due to Unauthorized error, enqueue request for future
        else if err.status is 401
          if SFDC.allowRequestQueueing
            LoggrUtil.log "Session inactive. Adding the request to the queue!"
            # Add request to queue to be retried after authentication.
            SFDC.requestQueue.push retryFn(401)
          else # If request queueing is not supported then just callback with error
            callback err, null

          # If sessionAlive is marked as true, then mark ready status as false and initiate authentication
          if SFDC.sessionAlive
            SFDC.setReady false
            SFDC.authenticator?()
        else
          SFDC.showCustomError err, ->
            callback err, null
            
    # onlyOnce = true, if you want to retry this AJAX request only once no matter if it succeeds or fails.
    retryFn = (previousError) ->
      return ->
        executeXHR getXHRConfig(previousError)

    executeXHR = (jqXHR) ->
      # If no valid active session present just add to request queue, if allowed
      isOnline = true
      if SFHybridApp? and !SFHybridApp.deviceIsOnline()
        LoggrUtil.logConnectionError()
        callback jqXHR, null
      else if !SFDC.sessionAlive and SFDC.allowRequestQueueing
        LoggrUtil.log "Session inactive. Adding the request to the queue!"
        SFDC.requestQueue.push retryFn()
      else
        $.ajax jqXHR
    
    executeXHR getXHRConfig()
          
  # 503
  @isServiceUnavailable: (err) ->
    JSON.stringify(err).indexOf("SERVER_UNAVAILABLE") isnt -1

  # 403
  @isRequestLimitExceeded: (err) ->
    JSON.stringify(err).indexOf("REQUEST_LIMIT_EXCEEDED") isnt -1

  # 400
  @isFieldCustomValidation: (err) ->
    JSON.stringify(err).indexOf("FIELD_CUSTOM_VALIDATION_EXCEPTION") isnt -1

  # 403
  @isForbidden: (err) ->
    errStr = JSON.stringify err
    return errStr.indexOf("Forbidden") isnt -1

  # 403
  @isRestAPIDisabled: (err) ->
    errStr = JSON.stringify err
    return errStr.indexOf("API_DISABLED_FOR_ORG") isnt -1 \
           and errStr.indexOf("REST API") isnt -1

  # 403
  @isChatterAPIDisabled: (err) ->
    errStr = JSON.stringify err
    return errStr.indexOf("FUNCTIONALITY_NOT_ENABLED") isnt -1 \
           or (errStr.indexOf("API_DISABLED_FOR_ORG") isnt -1 \
           and errStr.indexOf("Chatter Connect API") isnt -1)

  # 500
  @isUnknownError: (err) ->
    errStr = JSON.stringify err
    return err.status is 500 and errStr.indexOf("UNKNOWN_EXCEPTION") isnt -1

  @getMessageFromError: (err) ->
    responseText = JSON.parse err.responseText
    message = ""
    for msg in responseText
      if msg.message
        message += msg.message + "\n"
    message        

  @showCustomError: (err, callback) ->
    LoggrUtil.log "showCustomError " + JSON.stringify(err)

    # 400
    if SFDC.isFieldCustomValidation(err)
      Dialog.alert L.get("error"), L.get("error_custom_validation_rule")
    # Expose 400 and 404 directly to the user.
    else if err.status is 400 or err.status is 404
      # json = {"readyState":4,"responseText":"[{\"message\":\"The requested resource does not exist\",\"errorCode\":\"NOT_FOUND\"}]","status":404,"statusText":"Not Found"}
      LoggrUtil.log "Error: " + JSON.stringify(err)
      message = SFDC.getMessageFromError err
      Dialog.alert err.statusText, message
    else if err.status is 403
      if SFDC.isRestAPIDisabled(err)
        Dialog.alert L.get("error"), L.get("error_rest_api")
      else if SFDC.isChatterAPIDisabled(err)
        LoggrUtil.log "Chatter API disabled."
        Config.chatterEnabled = false
      else if SFDC.isRequestLimitExceeded(err)
        Dialog.alert L.get("error"), L.get("error_request_limit_exceeded")
      else if SFDC.isForbidden(err)
        message = SFDC.getMessageFromError err
        Dialog.alert err.statusText, message
    # 503
    else if SFDC.isServiceUnavailable(err)
      Dialog.alert L.get("error"), L.get("error_service_unavailable")
    
    else
      LoggrUtil.logError(JSON.stringify err)
      
    callback err, null

if document? then $(document).on 'online', -> SFDC.replayQueue()
window?.SFDC = SFDC
module?.exports = SFDC