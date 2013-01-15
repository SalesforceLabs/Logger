###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

# ### Loggr specific util class.
class LoggrUtil

  # Debug flag
  @DEBUG = true

  # Log string
  @MEM_LOG = ''

  # Max length of the log string
  @MAX_MEM_LOG_LENGTH = 25000

  # Formats a date string YYYY-MM-DD
  @getISODate: (date) ->
    date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate()

  # _return_ Flag if app runs on webserver
  @isWebApp: -> window?.location.protocol.indexOf('http') is 0

  # Check whether the app is running from local html file inside container, or from remote server such as heroku.
  # _return_ true if running locally.
  @isRunningLocally: ->
    /^file:$/.test(window.location.protocol)

  # Screen Tracking  
  # `screenName` Name of the screen to tag
  @tagScreen: (screenName) ->
    #LoggrUtil.log '### Track screen ' + screenName
    if not LoggrUtil.isRunningLocally()
      localyticsSession?.tagScreen screenName
    else
      LocalyticsPhoneGap?.tagScreen screenName

  # Event tracking  
  # `eventName` Name of the event to tag  
  # `data` e.g. {"key1": "value2", "key2": "value1"}
  @tagEvent: (eventName, data = {}) ->
    #LoggrUtil.log '### Track event ' + eventName + ' ' + JSON.stringify(data)
    if not LoggrUtil.isRunningLocally()
      localyticsSession?.tagEvent eventName, data
    else
      LocalyticsPhoneGap?.tagEvent eventName, data

  # `id` Enity Id
  # _return_ Type of the entity (Account, Contact, ...)
  @getType: (id) ->
    return null if not id
    if typeof id is 'string'
      prefix = id.substring(0,3)
      switch prefix
        when '001' then return 'Account'
        when '003' then return 'Contact'
        when '006' then return 'Opportunity'
        when '00Q' then return 'Lead'
        else
          throw new Error 'LoggrUtil.getType: Unsupported prefix ' + prefix
    throw new Error 'LoggrUtil.getType: Unsupported input ' + id

  # `str` String to HTML encode  
  # _return_ HTML encoded string
  @htmlEncode: (str) ->
    return $('<div/>').text(str).html()

  # Global log function.  
  # `msg` Log message
  @log: (msg) ->
    if LoggrUtil.DEBUG
      console.log msg
    
    NEWLINE = if Platform.isAndroid() then '%0D%0A' else '\n'
    LoggrUtil.MEM_LOG = new Date().toJSON() + ': ' + msg + NEWLINE + LoggrUtil.MEM_LOG
    if LoggrUtil.MEM_LOG.length > LoggrUtil.MAX_MEM_LOG_LENGTH
      LoggrUtil.MEM_LOG = LoggrUtil.MEM_LOG.substring 0, LoggrUtil.MAX_MEM_LOG_LENGTH

  # `arr` List of items  
  # `id` Id to look up  
  # _return_ Item matching the id or null when not found
  @getItemById = (arr, id) ->
    if arr?.length > 0
      for item in arr
        if item.Id is id
          return item
    return null

  # Check whether the eula has been accepted already by the device user.
  @isEulaAccepted = (callback)->
    Platform.getProperty 'logger_eula_status', (val) ->
      callback?(val is 'ACCEPTED')

  # Mark EULA as accepted for current device user.
  @acceptEula = (callback)->
    Platform.setProperty 'logger_eula_status', 'ACCEPTED', callback

  # Log a connection error.  
  # `error` Error description
  @logConnectionError = (error) ->
    Dialog.alert L.get("offline"), L.get("offline_alert")

  # Log an app error and send logs via email  
  # `error` Error description
  @logError = (error) ->
    LoggrUtil.log 'error ' + error
    Dialog.show L.get("error"), L.get("error_alert"), L.get("send"), ->
      Platform.sendLogs()

  # Helper function to check if hash is for detail
  @isDetailHash: (hash) -> hash.indexOf("#detail?id=") is 0

  # Helper function to check if hash is for related list
  @isRelatedHash: (hash) -> hash.indexOf("#related") is 0

  # Parses parameters out of the query string  
  # `hash` Query parameters as String
  @getQueryParams: (hash) ->
    result = {}
    queryString = hash.split('?')[1]
    re = /([^&=]+)=([^&]*)/g

    while (m = re.exec(queryString))
      result[decodeURIComponent(m[1])] = decodeURIComponent(m[2])

    return result

window?.LoggrUtil = LoggrUtil
module?.exports = LoggrUtil