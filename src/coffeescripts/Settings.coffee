###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Settings

  # Opens the dialog to post a viral post to Chatter
  @viralChatterPost: ->
    LoggrUtil.log "viralChatterPost"
    viralPost = L.get("viral_chatter_post")
    Dialog.show L.get("post_on_chatter"), viralPost, "Share", ->
      LoggrUtil.tagEvent 'settingsAction', {type:"Share on Chatter"}
      UI.showPending L.get("saving")
      SFDC.chatter "news/me", viralPost, (err, result) ->
        UI.hidePending(true, L.get("thanks"))

  # Checks if a record type is enabled  
  # `type` Record type  
  # `callback` Callback function (isEnabled)
  @isTypeEnabled: (type, callback) ->
    Settings.getObjectSettings (objects) ->
      for object in objects
        if object.id is type
          callback object.checked

  # Gets the object config as a hashmap  
  # `callback` Callback function (hashmap)
  @getObjectConfig: (callback) ->
    Settings.getObjectSettings (settings) ->
      config = {}
      for setting in settings
        config[setting.id] = setting.checked
      callback config

  # Gets the object settings partial to render the settings view.  
  # `callback` Callback function (partial)
  @getObjectSettings: (callback) ->
    objects = []
    types = Config.getSupportedObjects()

    getSetting = (type) ->
      #LoggrUtil.log "type #{type}"
      Platform.getProperty "show#{type}", (value) ->
        checked = true
        #LoggrUtil.log "Value for #{type} is " + value
        if value?
          # "true" for localstorage and "1" for app settings
          checked = (value is "true") or (value is "1")

        visibility = if checked then "true" else "hidden"
        objectClass = if checked then "settingsToggleOn" else "settingsToggleOff"
        objects.push {id: type, label:Config.getLabel(type), checked: checked, visibility:visibility, objectClass:objectClass}

        if types.length > 0
          getSetting types.shift()
        else
          #LoggrUtil.log "SETTINGS " + JSON.stringify(objects)
          callback objects

    getSetting types.shift()
    

  # Shows the settings
  @show: ->
    Settings.getObjectSettings (result) ->
      Settings.render result

  # Renders the settings after the object partial part has been computed
  @render: (objectSettings) ->
    LoggrUtil.log "show settings"
    
    UI.selectNav 'settings'

    partial =
      name: Platform.APP_NAME
      version: Platform.VERSION
      options1: [{label:L.get("share_on_chatter"), id:"shareChatter"}, {label:L.get("submit_feedback"), id:"feedback"}, {label:L.get("send_logs"), id:"logs"}, {label:L.get("follow_on_twitter"), id:"twitter"}]
      options2: [{label:L.get("about"), id:"about"}, {label:L.get("eula"), id:"eula"}]
      options3: [{label:L.get("logout"), id:"logout"}]
      objects: objectSettings
      isRetina: UI.isRetina()

    # add survey for non-Android
    if not Platform.isAndroid()
      partial.options1.unshift {label:L.get("take_a_quick_survey"), id:"survey"}

    # Localize
    partial.objectsLabel = L.get "objects"
    partial.email_to_salesforce = L.get "email_to_salesforce"
    partial.bcc_hint = L.get "bcc_hint"

    $content = $('#content')
    if not Platform.isAndroid()
      $content.empty().append(new Hogan.Template(T.settings).render(partial))
      
      # Super HACK to make scrolling work
      $content.css "-webkit-overflow-scrolling", ""
      setTimeout ->
        $content.css "-webkit-overflow-scrolling", "touch"
      , 50
    else
      $content.empty().append(new Hogan.Template(T.settings).render(partial))

    $content.find("#tableList").on 'touchstart', (event) ->
      target = UI.getClosestListItem event, '#list'
      UI.handleTouchDownState target, 'tableListUp', 'tableListPressed'

    $bccEmail = $content.find '#bccEmail'
    Platform.getProperty "bccEmail", (value) ->
      if value?
        $bccEmail.attr 'value', value
    $bccEmail.bind 'keyup input paste', (event) ->
      bccEmail = $bccEmail.attr 'value'
      Platform.setProperty "bccEmail", bccEmail

    $content.find("#bccEmailHelp").hammer(UI.buttonHammerOptions)
    .on 'tap', (event) ->
      LoggrUtil.tagEvent 'settingsAction', {type:"Email to Salesforce Help"}
      Platform.web "https://login.salesforce.com/help/doc/en/email_my_email_2_sfdc.htm"

    $content.find("#tableList").hammer(UI.buttonHammerOptions)
    .on 'tap', (event) ->
      target = UI.getClosestListItem event, '#tableList'

      switch target.id
        when SFDC.CONTACT, SFDC.ACCOUNT, SFDC.OPPORTUNITY, SFDC.LEAD
          $target = $("##{target.id}").find "img"
          isChecked = $target.attr("style") is "visibility:true"

          Settings.getObjectSettings (settings) ->
            if isChecked
              isOneSet = false
              for setting in settings
                if setting.id isnt target.id and setting.checked
                  isOneSet = true
                  break

              if not isOneSet
                Dialog.alert L.get("error"), L.get("deselect_all_objects", target.id)
                return
                    
            # Toggle
            isChecked = not isChecked

            Platform.setProperty "show#{target.id}", isChecked, (success) ->
              if success
                LoggrUtil.tagEvent 'settingsAction', {type:"Toggle Object", object: target.id, selected: isChecked}
                # Toggle selection
                newVisiblity = if isChecked then "visibility:true" else "visibility:hidden"
                objectClass = if isChecked then "settingsToggleOn" else "settingsToggleOff"
                $div = $("##{target.id}").find "div"
                if isChecked
                  $div.removeClass('settingsToggleOff').addClass 'settingsToggleOn'
                else
                  $div.removeClass('settingsToggleOn').addClass 'settingsToggleOff'
                $target.attr "style", newVisiblity
                LoggrUtil.log "set show#{target.id} " + isChecked + " success " + success

        when "shareChatter"
          Settings.viralChatterPost()
        when "twitter"
          LoggrUtil.tagEvent 'settingsAction', {type:"Follow on Twitter"}
          Platform.web "http://twitter.com/saleslogger"
        when "survey"
          LoggrUtil.tagEvent 'settingsAction', {type:"Survey"}
          LoggrUtil.log "show survey"
          Platform.web "http://uesurveys.salesforce.com/collector/Survey.ashx?Name=ProductFeedback_Logger_pilot"
        when "about"
          LoggrUtil.log "show about"
          LoggrUtil.tagEvent 'settingsAction', {type:"About"}
          modalInfo =
            title: 'About'
            closeText: 'Close'
            content: new Hogan.Template(T.about).render({appName:Platform.APP_NAME, version:Platform.VERSION})
          UI.showModal modalInfo
        when "eula"
          LoggrUtil.log "show eula"
          LoggrUtil.tagEvent 'settingsAction', {type:"EULA"}
          modalInfo =
            title: L.get("eula")
            closeText: L.get('close')
            content: Platform.getEULA()
          UI.showModal modalInfo
        when "feedback"
          LoggrUtil.tagEvent 'settingsAction', {type:"Send Feedback"}
          Platform.launchFeedback()
        when "logs"
          LoggrUtil.tagEvent 'settingsAction', {type:"Send Logs"}
          Platform.sendLogs()
        when "logout"
          Dialog.show L.get("logout"), L.get("logout_confirm"), L.get("ok"), ->
            $("#overlay").spin "large", "white"
            LoggrUtil.tagEvent 'settingsAction', {type:"Logout"}
            SFDC.logout ->
              LoggrUtil.log 'logout callback'
              $("#overlay").spin false
              ContainerAuth?.logout()
              location.href = '/'
        else
          throw new Error "Unknown Id #{target.id}"

window.Settings = Settings