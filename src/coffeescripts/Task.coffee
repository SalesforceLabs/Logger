###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Task extends BaseAction

  # Event constant
  @REFRESH_VIEW: "refreshView"

  constructor: (@json, @options, @callback) ->
    @type = LoggrUtil.getType @json.Id
    LoggrUtil.log "new Task #{@type}"

  # _return_ Flag if Chatter is enabled
  isChatterEnabled: ->
    Config.chatterEnabled and Config.isFeedTrackingEnabled(@type)

  # `type` SObject type
  # returns WhoId or WhatId if FLS is visible
  @getRelatedTo: (type) ->
    switch type
      when SFDC.CONTACT, SFDC.LEAD
        if Config.isFieldVisible "Task", "WhoId"
          reference = 'WhoId'
        else
          LoggrUtil.log "Warning: No WhoId specified since Task.Name is invisible"
      when SFDC.ACCOUNT, SFDC.OPPORTUNITY
        if Config.isFieldVisible "Task", "WhatId"
          reference = 'WhatId'
        else
          LoggrUtil.log "Warning: No WhatId specified since Task.RelatedTo is invisible"
      else
        throw new Error "Unkown type " + type

    reference

  # Render template
  render: ->
    task = new Hogan.Template T.task

    # When the subject is not editable it will be rendered as a hidden field
    subjectType = if @options.doShowSubject then 'text' else 'hidden'
    partial =
      subject: @options.subject
      text: @options.text
      subjectType: subjectType
      doShowLocation: @options.doShowLocation
      doShowDueDate: @options.doShowDueDate
      bodyPlaceholder: @options.bodyPlaceholder
      submitLabel: @options.submitLabel
      hasChatter: @isChatterEnabled()
      share_on_chatter: L.get("share_on_chatter")
      reminder_date: L.get("reminder_date")
      cancel: L.get("cancel")
      subject_placeholder: L.get("subject_placeholder")

    
    @form = $(task.render(partial))

    @androidNativeDatePicker()
    @androidDelay()

    if @isChatterEnabled()

      # Post to chatter is true by default
      isChatter = @options.chatterDefault

      $chatter = @form.find('#chatter')
      # Chatter is sticky so try to restore the last state
      # or set it to true initially.
      Platform.getProperty "chatter_#{@options.id}", (val) =>
        if val is "true"
          isChatter = true
          $chatter.toggleClass("active")
        else if val is "false"
          isChatter = false
        else if @options.chatterDefault
          $chatter.toggleClass("active")

    @form.find('#chatterPost').hammer({drag: false, transform: false, hold: false})
    .on 'tap', (event) =>

      isChatter = !isChatter
      # Save Chatter state to make it sticky
      newChatter = if isChatter then "true" else "false"
      Platform.setProperty "chatter_#{@options.id}", newChatter, (success) ->
        LoggrUtil.log "Toggle chatter " + isChatter

      $chatter.toggleClass "active"

    formValid = true
    
    # Listen for changes to the subject to disable the submit button when empty
    if @options.doShowSubject
      @form.find('#subject').bind 'keyup', (event) =>
        tempSubject = @form.find('#subject').attr('value')
        #LoggrUtil.log 'temp subject ' + tempSubject
        if tempSubject.trim().length is 0 and formValid
          LoggrUtil.log 'Disable'
          formValid = false
          @form.find('#submit').toggleClass('submitButton submitButtonDisabled')
        else if tempSubject.trim().length > 0 and not formValid
          LoggrUtil.log 'Enable'
          formValid = true
          @form.find('#submit').toggleClass('submitButton submitButtonDisabled')

    if @options.doShowLocation
      @lat = null
      @lon = null
      navigator.geolocation.getCurrentPosition (pos) =>
        @lat = pos.coords.latitude
        @lon = pos.coords.longitude

    if @type is SFDC.CONTACT and @json.AccountId and Config.hasType(SFDC.OPPORTUNITY) and Config.isFieldVisible "Task", "WhatId"
      
      if Config.isFieldVisible SFDC.OPPORTUNITY, "AccountId"
        cachedOppties = Model.getOpportunitiesForAccount @json.AccountId

        renderOpportunities = (records) =>
          partial =
            opportunities: records
            oppty_select_label: L.get("oppty_select_label")
          oppties = new Hogan.Template(T.opportunity_select).render partial
          @form.find('#subject').after oppties

          #@dispatchEvent Task.REFRESH_VIEW

        if cachedOppties
          renderOpportunities cachedOppties
        else
          SFDC.opportunities @json.AccountId, (err, result) =>
            if not err and result.records.length > 0
              Model.setOpportunitiesForAccount @json.AccountId, result.records
              renderOpportunities result.records

    @initCancelButton()

    @initSubmitButton().hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      event.preventDefault()
      LoggrUtil.log 'form valid ' + formValid
      if formValid
        LoggrUtil.log 'Create Task'
        subject = @form.find('#subject').attr 'value'
        body = @form.find('#body').attr 'value'
        
        if @options.doShowLocation and @lat? and @lon?
          body += " http://maps.google.com?q="+encodeURIComponent(@lat+"," + @lon)
        
        payload =
          subject: subject
          status: @options.status
          description: body

        if @options.doShowDueDate
          dueDate = @form.find('#dueDate').attr('value')
          payload.activityDate = dueDate if dueDate != ''

        if @options.status is "Completed" and Config.hasTaskType
          LoggrUtil.log "Set explicit Task type."
          payload.type = @options.submitLabel

        if @options.status is "Completed"
          activityDate = new Date()
          payload.activityDate = LoggrUtil.getISODate activityDate

        # Set WhoId or WhatId when FLS is visible
        reference = Task.getRelatedTo @type
        payload[reference] = @json.Id if reference?

        if @type is SFDC.CONTACT
          opptyId = @form.find('#opportunity option:selected').attr('id')
          if opptyId isnt ""
            LoggrUtil.log "Related to Opportunity"
            payload.WhatId = opptyId
        
        if isChatter
          chatterText = subject
          if body?.length > 0
             chatterText += ' - ' + body
          else
            chatterText += '.'
          ###chatterPost =
            text: chatterText
            _csrf: @options.csrfToken
            resource: ###

          SFDC.chatter "record/#{@json.Id}", chatterText, (err, data) =>
            if err
              LoggrUtil.log 'Failed posting to Chatter ' + err
            else
              LoggrUtil.log 'Posted update about task creation on chatter!'

        @disableFields true

        UI.showPending L.get("saving")

        LoggrUtil.tagEvent 'Create Task',
          type: @type
          task: @options.submitLabel
          chatter: isChatter
          
        SFDC.create 'Task', payload, (err, data) =>
          UI.hidePending(err is null)
          @callback err, data
          @disableFields false if err

    return @form

  @getPayload: (task, json) ->
    
    options =
      id: task
      chatterDefault: false
      doShowLocation: false
      doShowSubject: false
      doShowDueDate: false

    switch task
      when 'checkIn'
        options.subject = L.get("visited_customer", json.Name)
        options.chatterDefault = true
        options.doShowLocation = true
        options.status = 'Completed'
        options.bodyPlaceholder = L.get("checkin_body")
        options.submitLabel = L.get("check-in")
      when 'followUp'
        options.subject = L.get("follow-up")
        options.doShowSubject = true
        options.doShowDueDate = true
        options.bodyPlaceholder = L.get("what_next")
        options.submitLabel = L.get("save_task")
      when 'call'
        options.subject = L.get("call")
        options.status = 'Completed'
        options.bodyPlaceholder = L.get("call_content")
        options.submitLabel = L.get("log_call")
      when 'email'
        options.subject = L.get("email")
        options.status = 'Completed'
        options.bodyPlaceholder = L.get("email_content")
        options.submitLabel = L.get("log_email")

    return options

window?.Task = Task
module?.exports = Task