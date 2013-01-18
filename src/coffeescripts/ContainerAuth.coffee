###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class ContainerAuth

  # OAuth Client Id
  @CLIENT_ID = "LOGGER_CLIENT_ID"

  # OAuth redirect Url
  @REDIRECT_URI = 'loggr:///login/success/redirect'

  # OAuth scopes
  @SCOPES = ['api', 'chatter_api']

  # Logs in the user using the salesforce mobile container's oauth plugin  
  # `callback` Callback function which expects optional err message
  @authenticate: (callback) ->
    performLogin = ->
      LoggrUtil.log 'performLogin'

      if !SFHybridApp.deviceIsOnline()
        LoggrUtil.logConnectionError()
        callback 'DEVICE_OFFLINE'
      else
        LoggrUtil.log 'Device is online. Initiating OAuth'
        # Flag to track if authentication takes much longer than expected and retry authentication on user request
        isAuthenticating = true

        # Setting the autoRefreshOnForeground and autoRefreshPeriodically attributes to false.
        # The app handles the session expired errors automatically and reinitiates the authentication.
        oauthProperties = new SalesforceOAuthPlugin.OAuthProperties(
          ContainerAuth.CLIENT_ID, 
          ContainerAuth.REDIRECT_URI, 
          ContainerAuth.SCOPES, 
          false, false)

        updateAppSession = (oauthInfo) ->
          SFDC.setInstanceUrl oauthInfo.instanceUrl
          SFDC.setSID oauthInfo.accessToken
          # Mark the SFDC library as ready to make API calls
          SFDC.setReady true

        # Launch authentication via Salesforce oauth plugin
        SalesforceOAuthPlugin.authenticate (oauthInfo) ->
          LoggrUtil.log 'SalesforceOAuthPlugin.authenticate successful'
          isAuthenticating = false
          SFDC.setContainer true
          updateAppSession(oauthInfo)
          $(document).on 'salesforceSessionRefresh', (event) ->
            LoggrUtil.log 'salesforceSessionRefresh event fired.'
            updateAppSession(event.originalEvent.data)
          callback null, oauthInfo
        , (err) ->
          LoggrUtil.log('Failed to login user: ' + JSON.stringify err)
          isAuthenticating = false
          errStr = JSON.stringify err
          alert L.get("auth_error_alert", errStr)
          ContainerAuth.authenticate callback
        , oauthProperties


    performLogin()

  # Revokes the salesforce mobile container session for current user
  @logout: ->  SalesforceOAuthPlugin.logout()

window.ContainerAuth = ContainerAuth