###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Action extends EventDispatcher

  # Event constants
  @OPPTY_CHANGE: "opptChange"
  @REFRESH_VIEW: "refreshView"

  # _private_ Flag for absolute positioning
  _useAbsolutePosition: true

  # JQuery instance of the detail div
  detailContent: null

  # JQuery instance of the form
  form: null

  # _private_ helper function for iScroll support
  _setViewProperties: ($view) ->
    flexHeight = $view.css('bottom', 'auto').height()
    fixedBottomHeight = $view.addClass('absolute').css('bottom', '0').height()
    if fixedBottomHeight < flexHeight
      @_useAbsolutePosition = false
      $view.css('bottom', 'auto')
    else
      @_useAbsolutePosition = true

  # Shows the action sheet or invokes action when no sheet is need  
  # `actionId` Id of the action  
  # `$detailContent` Jquery content div  
  # `json` Record object  
  # `invokeUrl` Optional invokeUrl
  show: (actionId, $detailContent, json, invokeUrl) ->
    LoggrUtil.tagScreen 'Action ' + actionId

    @detailContent = $detailContent

    # Don't disable dragging for map action
    # No form will be shown
    if actionId isnt 'map'
      Panel.draggingEnabled = false

    switch actionId
      when 'checkIn'
        options = Task.getPayload 'checkIn', json
        if invokeUrl
          options.text = decodeURIComponent invokeUrl.parameter 'text'
          xSuccess = invokeUrl.xSuccess()
          xCancel = invokeUrl.xCancel()
          xError = invokeUrl.xError()
        @createTask json, options, (err, data) =>
          if !data and xCancel
            LoggrUtil.log "go back x-cancel #{xCancel}"
            location.href = xCancel
          if data and xSuccess
            LoggrUtil.log "go back x-success #{xSuccess}"
            location.href = xSuccess
      when 'close_date', 'stage_name'
        options =
          showCloseDate: actionId is 'close_date'
          showStageName: actionId is 'stage_name'

        if actionId is 'close_date'
          options.date = json.CloseDate
        else if actionId is 'stage_name'
          options.stages = Config.getActiveOpptyStages json

        @changeOppty json, options

      when 'followUp'
        options = Task.getPayload 'followUp', json
        @createTask json, options
      when 'takeNote'
        @takeNote json
      when 'call'
        @call json
      # Contact only.
      when 'email'
        if json.Email
          Platform.getProperty "bccEmail", (value) =>
            bccEmail = if value? and value isnt "" then value else null
            LoggrUtil.log "BCC " + value + " set " + bccEmail
            Platform.mail json.Email, null, null, bccEmail
            if not bccEmail
              options = Task.getPayload 'email', json
              @createTask json, options, (err, data) =>
                @close() if not err
            else
              Panel.draggingEnabled = true
        else
          @edit Edit.EMAIL, json
      when 'map'
        query = Model.getGeoQuery json
        if query
          Platform.maps query
        else
          @edit Edit.ADDRESS, json
      else
        LoggrUtil.log 'Error: Undefined actionId ' + actionId

  # Shows the add phone form
  # `editType` Edit.PHONE, Edit.EMAIL or Edit.ADDRESS  
  # `json` Record object  
  # `callback` Optional callback function to handle the result (data)
  edit: (editType, json, callback) ->
    edit = new Edit editType, json, =>
      callback?()
      @close()

    @renderForm edit.render()

  # Called after every successful action (task, note)
  # to invoke viral actions
  postAction: ->
    Platform.getProperty "actionCount", (val) ->
      LoggrUtil.log "actionCount #{val}"
      if isNaN(val) or val is null
        Platform.setProperty "actionCount", 1, (success) ->
      else
        val = parseInt(val) + 1
        Platform.setProperty "actionCount", val, (success) ->
          LoggrUtil.log "increment actionCount #{val}: #{success}"

        if val is 3
          # use timeout (>700ms) since save pending animation
          # is interfering with dialog popup
          setTimeout ->
            Settings.viralChatterPost()
          , 1500

  # Shows the create task form
  # `detail` Contact or Account JSON  
  # `options` Object with following options: title, subject, status, doShowSubject, doShowDueDate  
  # `callback` Callback function to handle the result (data)
  createTask: (detail, options, callback) ->
    task = new Task detail, options, (err, data) =>
      callback?(err, data)
      if not err
        # Cancel has no data
        @postAction() if data
        @close()
      else
        LoggrUtil.log "Error: Task creation failed."
    LoggrUtil.log "createTask #{detail} " + JSON.stringify(options)
    ###task.addEventListener Task.REFRESH_VIEW, =>
      console.log "Task.REFRESH_VIEW"
      @refreshView()###
    @renderForm task.render()

  # Shows the create note form
  # `detail` Contact or Account JSON  
  # `callback` Callback function to handle the result (data)
  takeNote: (detail, options) ->
    note = new Note detail, options, (err, data) =>
      if not err
        @postAction()
        @close()
      else
        LoggrUtil.log "Error: Note creation failed."
    @renderForm note.render()

  changeOppty: (json, options) ->
    LoggrUtil.log "change close date"

    task = new OpptyEdit json, options, =>
      @dispatchEvent Action.OPPTY_CHANGE, json
      @postAction()
      @close()
    @renderForm task.render()

  # Call action  
  # `json` Record object
  call: (json) ->
    call = new Call json, (action, data) =>
      LoggrUtil.log "Call action #{action}"
      @close()
      if action
        switch action
          when "call", "log"
              
            Platform.call data if action is "call"

            setTimeout =>
              options = Task.getPayload 'call', json
              @createTask json, options
            , 500

          when "edit"
            @edit Edit.PHONE, json, =>
              @close()
              setTimeout =>
                # re-open call sheet
                @call json
              , 1
    
    @renderForm call.render()

  # Needed for iScroll
  refreshView: ->
    @_setViewProperties @form
    if not @_useAbsolutePosition 
      @detailContent?.hide()
      @form.removeClass('absolute')
    @dispatchEvent Action.REFRESH_VIEW

  # Closes the action sheet
  close: ->
    $formElem = @form
    @detailContent.show()
    if not Platform.isAndroid()
      $formElem.addClass 'absolute'
      $formElem.css
        webkitTransform: 'translate3d(0, 100%, 0)'
      .on 'webkitTransitionEnd', =>
        $formElem.hide()
        @dispatchEvent Action.REFRESH_VIEW
        setTimeout () ->
          $formElem.remove()
        , 10
    else
      $formElem.remove()

    Panel.draggingEnabled = true
  
  # Renders the form element on the page with appropriate transition  
  # `formElem` jQuery instance of html element to be added to the detail section
  renderForm: ($formElem) ->

    @form = $formElem

    if not Platform.isAndroid()
      UI.tapReady = false

      @detailContent.before($formElem)
      .on 'orientationchange', =>
        @refreshView()

      $formElem.addClass('absolute')
      .css
        visibility:'hidden'
        webkitTransitionProperty: 'none'
        webkitTransform: 'translate3d(0, 100%, 0)'
      .on 'webkitTransitionEnd', =>
        @refreshView()
        $formElem.off 'webkitTransitionEnd'
        UI.tapReady = true

      @_setViewProperties $formElem
      
      setTimeout ->
        $formElem.css '-webkit-backface-visibility', 'hidden'
        $formElem.css '-webkit-transition-duration', '300ms'
        $formElem.css '-webkit-transition-timing-function', 'ease-out'
        $formElem.css
          visibility:''
          webkitTransitionProperty: '-webkit-transform'
          webkitTransform: 'translate3d(0, 0%, 0)'
      , 10
    else
      @detailContent.before($formElem)
      .on 'orientationchange', =>
        @refreshView()
      $formElem.addClass('absolute')
      @_setViewProperties $formElem
      $formElem.css
        webkitTransitionProperty: '-webkit-transform'
        webkitTransform: 'translate3d(0, 0%, 0)'


window?.Action = Action
module?.exports = Action