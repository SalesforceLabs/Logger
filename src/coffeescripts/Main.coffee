###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

# ### Main is the main class
class Main

  # Flag if the launch process is complete
  isLaunchComplete: false

  # Flag to ignore a history.back
  ignorePop: false

  # Instance of the search class
  search: null

  # Instance of the detail class
  detail: null

  constructor: ->
    LoggrUtil.log "new Main"

    L.initFile "locales.json", =>
      # when the app is running as a web app run init
      # or wait for the Cordova deviceready event
      if LoggrUtil.isWebApp()
        @init()
      else
        document?.addEventListener "deviceready", =>
          @init()
        , false


  # Init function  
  # Adds event listeners and checks if EULA has been accepted
  init: ->
    LoggrUtil.log "init"

    # dispatched from container.hogan
    Platform.addEventListener "openUrl", (url) =>
      invokeUrl = new InvokeUrl url
      LoggrUtil.log "InvokeUrl #{url}"
      action = @invokeUrl.action 'x-callback-url'
      if action
        id = invokeUrl.parameter 'id'
        @detail.setInvokeUrl invokeUrl
        LoggrUtil.log "InvokeUrl action #{action} on Id: #{id}"
        @showHash "#detail?id=" + id

    @detail = new Detail()
    @detail.addEventListener Detail.SHOW_HASH, (hash) =>
      @showHash hash

    @search = new Search()
    @search.addEventListener Search.SELECT, (id) =>
      @showHash "#detail?id=#{id}"
    
    # Check EULA
    @checkEULA => 
      # Add online event listener to re-initiate launch process when we are online
      $(document).on 'online', => @launch() if not @isLaunchComplete


  # Check EULA and launch the app once EULA is accepted.  
  # `callback` Callback function invoked when accepted
  checkEULA: (callback) ->
    LoggrUtil.isEulaAccepted (val) ->
      # Need this hack to enable casperjs automation
      isAuth = window.location.search.indexOf("auth=true") isnt -1
      if not val and not isAuth
        LoggrUtil.log "show eula"
        LoggrUtil.tagScreen 'EULA'
        modalInfo =
          title: L.get("eula")
          closeText: L.get("accept")
          content: Platform.getEULA()
        UI.showModal modalInfo, ->
          LoggrUtil.acceptEula callback
      else
        callback()

  # Executes the steps to launch the app after the EULA is accepted
  launch: ->
    isOnline = true
    # check if device is offline
    if SFHybridApp?
      isOnline = SFHybridApp.deviceIsOnline()
    if not isOnline
      LoggrUtil.logConnectionError()
    else 
      LoggrUtil.log 'device is online. Trying authentication'
      # Initiate authentication if a container app, else directly initialize the app.
      if cordova?
        $('body').spin "large", "white"
        @authenticate (err) =>
          $('body').spin false
          @getUser() if not err
      else
        @run()

  # Authenticate User  
  # `callback` Callback invoked when authentication is complete
  authenticate: (callback) ->
    if ContainerAuth?
      $('body div#start button').hide()
      ContainerAuth.authenticate (err, oauthInfo) =>
        @oauthInfo = oauthInfo
        if err
          LoggrUtil.log 'Error: ' + err
          $('body div#app').empty().hide()
          $('body div#start').show()
        callback?(err)
    else
      $('body div#app').empty().hide()
      $('body div#start').show()

  getUser: ->
    # disable localization for now
    return @run()

    SFDC.get "User", @oauthInfo.userId, null, (err, result) =>
      if err
        LoggrUtil.log "Error " + JSON.stringify(err)
      else
        LoggrUtil.log "User Locale " + result.LanguageLocaleKey
        localeKey = result.LanguageLocaleKey
        if localeKey.indexOf("de") is 0
          L.changeLocale "de"

      @run()

  # Prepares the UI after authentication
  run: ->
    @isLaunchComplete = true

    # Set the method for authentication callback when session expires.
    SFDC.setAuthenticator @authenticate

    # Bind hash location change event
    $(window).on 'popstate', (e) =>
      state = e.originalEvent.state
      LoggrUtil.log "POP " + state
      return if not state

      if @ignorePop
        LoggrUtil.log "IGNORE"
        @ignorePop = false
      else
        @showHash location.hash, state

    $('body div#start').hide()
    $('body div#app').empty().show()
    .append(new Hogan.Template(T.home).render({isRetina: UI.isRetina()}))

    $('#mainNav li').on "touchstart", (event) =>
      event.preventDefault()
      switch event.currentTarget.id
        when "recentNav" then @showHash '#recent' + Model.getLastType() + 's'
        when "searchNav" then @showHash '#search'
        when "settingsNav" then @showHash '#settings'
        else
          alert 'Error: Unkown navigation option ' + id

    # Mark the SFDC library as ready to make API calls
    SFDC.setReady true

    Config.init (err) =>
      if not err
        # Find last selected object
        Platform.getProperty "LastType", (type) =>
          LoggrUtil.log "getProperty LastType: #{type}"
          hash = if type? then "#recent#{type}s" else "#recentContacts"
          LoggrUtil.log "Initial hash: #{hash}"
          @showHash if location.hash is '' then hash else location.hash

  # Swtch content  
  # `hash` Hash of the content  
  # `state` Optional state when invoked from history.back
  showHash: (hash, state) ->
    LoggrUtil.log 'showHash ' + hash + ' current: ' + location.hash

    if state
      if Panel.panels.length > 0
        LoggrUtil.log "BACK"
        Panel.pop()
        if Panel.panels.length is 0
          @detail.resetDetailScroller()
        else if Panel.panels.length is 1
          @detail.resetRelatedScroller()
        return
    else if Panel.panels.length is 2
      while Panel.panels.length
        Panel.pop()
      ignorePop = true
      history.go(-2)
      setTimeout =>
        @showHash hash, state
      , 100
      LoggrUtil.log "-2"
      return
    else if Panel.panels.length is 1
      if LoggrUtil.isDetailHash(hash)
        Panel.pop =>
          @showHash hash, state
        return

    #if location.hash isnt hash
    if LoggrUtil.isDetailHash(location.hash) and LoggrUtil.isDetailHash(hash)
      LoggrUtil.log "REPLACE #{hash}"
      history.replaceState hash, null, hash
    else if not state
      LoggrUtil.log "PUSH #{hash}"
      history.pushState hash, null, hash

    switch hash
      when "#recentContacts" then @showList SFDC.CONTACT
      when "#recentAccounts" then @showList SFDC.ACCOUNT
      when "#recentOpportunities", "#recentOpportunitys" then @showList SFDC.OPPORTUNITY
      when "#recentLeads" then @showList SFDC.LEAD
      when "#search" then @search.show()
      when "#settings" then Settings.show()
      else
        if LoggrUtil.isDetailHash(hash)
          params = LoggrUtil.getQueryParams location.hash
          @detail.show params['id']
        else if LoggrUtil.isRelatedHash(hash)
          params = LoggrUtil.getQueryParams location.hash
          @detail.showRelated params['type'], params['accountId']
        else
          throw new Error 'Unknown hash: ' + hash

  

  # `partial` list, isAccount, isContact, isEmpty
  renderList: (partial, objectSettings) ->
    # This is causing the container to crash when switching
    # between contacts and accounts
    if not UI.domRefreshCount
      UI.refreshDOM() #HACK: For some reason the overflow scroll doesn't work until we re-attach the home div

    getObjectSetting = (type) ->
      for setting in objectSettings
        if setting.id is type
          return setting.checked

    partial.showContacts = getObjectSetting SFDC.CONTACT
    partial.showAccounts = getObjectSetting SFDC.ACCOUNT
    partial.showOpportunities = Config.hasType(SFDC.OPPORTUNITY) and getObjectSetting(SFDC.OPPORTUNITY)
    partial.showLeads = Config.hasType(SFDC.LEAD) and getObjectSetting(SFDC.LEAD)

    partial.contactsLabel = Config.getLabel SFDC.CONTACT
    partial.accountsLabel = Config.getLabel SFDC.ACCOUNT
    partial.opportunitiesLabel = Config.getLabel SFDC.OPPORTUNITY
    partial.leadsLabel = Config.getLabel SFDC.LEAD

    partial.no_recently_viewed = L.get("no_recently_viewed")
    partial.search = L.get("search")

    $('#app #content').empty().append(new Hogan.Template(T.list).render partial)

    $('#app #content').find("#searchRecord").hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      @showHash "#search"

    # select navigation
    UI.selectNav 'recent' if location.hash.indexOf('#recent') is 0

    # don't show down state for Android since this causes list to scroll up
    # see http://stackoverflow.com/questions/11668873/scroll-jump-to-top-with-webkit-overflow-touch-on-android#_=_
    if not Platform.isAndroid()
      $('#list').on 'touchstart', (event) ->
        if UI.tapReady
          target = UI.getClosestListItem event, '#list'
          UI.handleTouchDownState target, 'listUp', 'listPressed'

    # Attaching the event to the outer list element instead of individual list item
    # This reduces the number of event listeners on the DOM and making it more responsive.
    $('#list').hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      if UI.tapReady
        @showHash "#detail?id=" + UI.getListItemId(event, '#list')

    if partial.isContact
      $('#Contacts').addClass 'selectedType'
      $('#Accounts').addClass 'unselectedType'
      $('#Opportunities').addClass 'unselectedType'
      $('#Leads').addClass 'unselectedType'
    if partial.isAccount
      $('#Contacts').addClass 'unselectedType'
      $('#Accounts').addClass 'selectedType'
      $('#Opportunities').addClass 'unselectedType'
      $('#Leads').addClass 'unselectedType'
    if partial.isOpportunity
      $('#Contacts').addClass 'unselectedType'
      $('#Accounts').addClass 'unselectedType'
      $('#Opportunities').addClass 'selectedType'
      $('#Leads').addClass 'unselectedType'
    if partial.isLead
      $('#Contacts').addClass 'unselectedType'
      $('#Accounts').addClass 'unselectedType'
      $('#Opportunities').addClass 'unselectedType'
      $('#Leads').addClass 'selectedType'

    $('#types li').hammer(UI.buttonHammerOptions)
    .on 'touchstart', (event) =>
      #LoggrUtil.tagEvent 'Switch type', {type:event.currentTarget.id}
      newHash = '#recent' + event.currentTarget.id
      if location.hash is newHash
        LoggrUtil.log "refresh " + event.currentTarget.id
        switch event.currentTarget.id
          when "Accounts"
            @showList SFDC.ACCOUNT, true
          when "Contacts"
            @showList SFDC.CONTACT, true
          when "Opportunities"
            @showList SFDC.OPPORTUNITY, true
          when "Leads"
            @showList SFDC.LEAD, true
      else
        @showHash newHash

  # Shows a list of accounts or contacts.  
  # Tries to get data from memory cache or loads it up when not available.  
  # `type` Record type  
  # `reset` Flag if the list should be cleared before loading the new one.  
  showList: (type, reset = false) ->
    Model.setLastType type

    render = (list, objectSettings) =>
      for item in list
        item.uiName = Model.getDetailName item

      @renderList Model.getSummariesPartial(type, list), objectSettings
      Platform.setProperty "LastType", type, (success) ->
        LoggrUtil.log "Set LastType #{type}: #{success}"

    if reset
      $('#app #content #list').empty()
      Model.resetCache()

    Settings.getObjectSettings (objectSettings) =>
      for object in objectSettings
        if object.checked
          firstEnabled = object
        if object.id is type
          objectEnabled = object.checked  

      if not objectEnabled
        if firstEnabled
          type = firstEnabled.id
        else return

      summaries = Model.getSummaries type
      if summaries?.length is 0
        $overlay = $("#overlay")
        $overlay.spin "large", "white"
        SFDC.get type, null, null, (err, data) ->
          $overlay.spin false
          if !err
            LoggrUtil.log "Loaded MRUs " + type + ' length: ' + data.recentItems.length
            render Model.setSummaries(type, data.recentItems), objectSettings
      else
        render summaries, objectSettings


module?.exports = Main

$ ->
  main = new Main()

# global sign-in function used for web version.
window?.signIn = ->
  LoggrUtil.log 'signIn'
  location.href = window.location.protocol + '//' + window.location.host + '/authenticate'  
