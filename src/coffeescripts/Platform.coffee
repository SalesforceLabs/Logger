###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Platform

  # Version string. Build number is replaced on build server.
  @VERSION = '1.4.0 {{BUILD_NUMBER}}'

  # Name of the application
  @APP_NAME = "Logger"

  # Feedback email address
  @FEEDBACK_EMAIL = 'saleslogger@salesforce.com'

  # Array of event listeners.
  @_eventListeners = []

  # Returns flag if user agent is Android
  @isAndroid: -> navigator?.userAgent.toLowerCase().indexOf("android") isnt -1

  # _return_ EULA template. 
  @getEULA: ->
    if not Platform.isAndroid()
      eula = new Hogan.Template(T.eula_ios).render({appName:Platform.APP_NAME})
    else
      eula = new Hogan.Template(T.eula_android).render()
    eula

  # Adds the event listener to the Array.  
  # `event` Event name as String  
  # `callback` Function with (data) signature
  @addEventListener: (event, callback) ->
    LoggrUtil.log "addListener #{event}"
    Platform._eventListeners.push {event:event, callback:callback}

  # Dispatches the event to all corresponding listeners.
  @dispatchEvent: (event, data) ->
    LoggrUtil.log "dispatchEvent #{event}"
    for listener in Platform._eventListeners
      if listener.event is event
        listener.callback data

  # Call phone number  
  # `phone` Number to call
  @call: (phone) ->
    if cordova? and not Platform.isAndroid()
      window.location = 'telprompt://' + phone
    else
      window.location = 'tel:' + phone

  # Email  
  # `email` Email address  
  # `subject` Optional subject  
  # `body` Optional body  
  # `bcc`  Optional bcc address
  @mail: (email, subject = '', body = '', bcc = null) ->
    if window.plugins.emailComposer? and not Platform.isAndroid()
      # signature subject,body,toRecipients,ccRecipients,bccRecipients,bIsHTML
      window.plugins.emailComposer.showEmailComposer(subject, body, email, null, bcc)
    else
      emailLink = "mailto:#{email}?subject=#{subject}&body=#{body}"
      emailLink += "&bcc=#{bcc}" if bcc

      location.href = emailLink

  # Open maps  
  # `query` Maps query
  @maps: (query) ->
    location = ""
    if cordova? and not Platform.isAndroid()
      location = 'maps:' + query
    else
      location = 'https://maps.google.com/maps?' + query
    window.location = location

  # Open website  
  # `url`Url to open
  @web: (url) ->
    if cordova? and not Platform.isAndroid()
      #window.plugins.childBrowser.showWebPage url
      cordova.exec "ChildBrowserCommand.showWebPage", url
    else
      window.location = url

  # Launch feedback email
  @launchFeedback = ->
    body =  "Feedback " + Platform.VERSION + " #{device.platform} #{device.version}"
    Platform.mail Platform.FEEDBACK_EMAIL, body

  # Send app logs via email
  @sendLogs = ->
    body = Platform.APP_NAME + " " + Platform.VERSION + " #{device.platform} #{device.version}"
    Platform.mail Platform.FEEDBACK_EMAIL, body, LoggrUtil.MEM_LOG

  # Get the persistent app property. Has to be asynchronous for support cordova callouts.  
  # `key` Property for which value has to be fetched  
  # `callback` Function to be called back with property value
  @getProperty = (key, callback) ->
    if cordova? and not Platform.isAndroid()
      window.plugins.applicationPreferences.get key, (val) ->
        callback val
      , ->
        callback()
    else if localStorage?
      callback localStorage.getItem(key)
    else
      callback()

  # Set the persistent app property. Has to be asynchronous for support cordova callouts.  
  # `key` Property for which value has to be set  
  # `value` Value to be set for this property  
  # `callback` Function to be called back with property value  
  @setProperty = (key, value, callback) ->
    if cordova? and not Platform.isAndroid()
      window.plugins.applicationPreferences.set key, value, ->
        callback true
      , ->
        callback false
    else if localStorage?
      localStorage.setItem(key, value)
      callback? true
    else
      callback? false

  # Shows the activity indicator in the status bar
  @showStatusBarActivityIndicator = () ->
    if cordova? and not Platform.isAndroid()
      cordova?.exec "UIUtils.showActivityIndicator"

  # Hides the activity indicator in the status bar
  @hideStatusBarActivityIndicator = () ->
    if cordova? and not Platform.isAndroid()
      cordova?.exec "UIUtils.hideActivityIndicator"

window?.Platform = Platform
module?.exports = Platform