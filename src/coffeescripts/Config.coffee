###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Config

  # Array of potential contact fields
  @CONTACT_FIELDS: ["AccountId", "Phone", "MobilePhone", "Email", "Title", "MailingStreet", "MailingCity", "MailingState", "MailingPostalCode"]
  # Array of potential account fields
  @ACCOUNT_FIELDS: ["Phone", "BillingStreet", "BillingCity", "BillingState", "BillingPostalCode"]
  # Array of potential oppty fields
  @OPPORTUNITY_FIELDS: ["AccountId", "StageName", "Amount", "CloseDate"]
  # Array of potential lead fields
  @LEAD_FIELDS: ["Company", "Email", "Title", "Phone", "MobilePhone", "City", "Street", "PostalCode", "State"]

  # Flag if task types are supported
  @hasTaskType: false

  # Get Chatter user via Connect worked
  @chatterEnabled: true

  # Chatter only has no Tasks
  @hasTasks: true

  # Task array of recordTypeInfos
  @recordTypeInfos: null

  # _private_ dictionary of supported types
  @_types: {}

  # `type` Record type  
  # _return_ Flag if the type is supported.
  @hasType: (type) -> Config._types[type]?

  # _private_ dictionary of enabled feed trackings
  @_feedTrackingEnabled: {}

  # `type` Record type
  # _return_ flag if feed tracking is enabled.
  @isFeedTrackingEnabled: (type) ->
    return Config._feedTrackingEnabled[type]

  # _private_ hashmap of all fields  
  # Hashmap key is #{object}_#{field.name}
  @_fields: {}

  # Account fields from describe call  
  # Stored in hashmap for faster access  
  # `type` Record type  
  # `fields` Array of fields
  @_setFields: (type, fields) ->
    for field in fields
      Config._fields["#{type}_#{field.name}"] = field

  # `type` Record type  
  # `fieldName` Name of the field to check  
  # _return_ Flag if the field is visible
  @isFieldVisible: (type, fieldName) ->
    Config.getField(type, fieldName)?

  # `type` Record type  
  # `fieldName` Name of the field to look up  
  # _return_ Field configuration
  @getField: (type, fieldName) ->
    Config._fields["#{type}_#{fieldName}"]

  # _private_ hashmap of record labels
  @_labels: {}

  # `type` Record type  
  # _return_ Label of the record type
  @getLabel: (type) -> Config._labels[type]

  # init function to get all configuration  
  # `callback` Callback function invoked after configuration is ready
  @init: (callback) ->
    Config.describeGlobal (err) =>
      showCallSFDC = ->
        notSupportedMessage = "Uhoh! Your Salesforce account doesn't meet the minimum requirements to use Logger.\nCall Salesforce to upgrade today!"
        Dialog.show "Initialization failed", notSupportedMessage, "Call", ->
          Platform.call "1-800-667-6389"

      if not err
        if Config.hasType(SFDC.ACCOUNT) and Config.hasType(SFDC.CONTACT)
          Config.describeObjects()
          Config.checkChatterEnabled()
          callback null
        else
          showCallSFDC()

      # when /sobject is forbidden the salesforce edition is
      # most likely chatter only
      else if SFDC.isForbidden(err)
        showCallSFDC()
      # 401 comes when not authenticated yet
      else if err.status isnt 401
        LoggrUtil.logError err

  # @see [docs](http://www.salesforce.com/us/developer/docs/api_rest/Content/resources_describeGlobal.htm)
  @describeGlobal: (callback) ->
    SFDC.get '', null, null, (err, result) ->
      if !err
        hasTasks = false
        for so in result.sobjects
          switch so.name
            when SFDC.ACCOUNT, SFDC.CONTACT, SFDC.OPPORTUNITY, SFDC.LEAD
              LoggrUtil.log "Describe global found #{so.name}. Feed tracking enabled: " + so.feedEnabled
              Config._labels[so.name] = so.labelPlural
              Config._types[so.name] = so
              Config._feedTrackingEnabled[so.name] = so.feedEnabled

            when "Task"
              LoggrUtil.log "Describe global found Task"
              hasTasks = true

        Config.hasTasks = hasTasks
      else
        LoggrUtil.log "Describe Global failed " + JSON.stringify(err)

      callback err

  # Invokes describe call for all supported record types.  
  # `callback` Callback function invoked when complete.
  @describeObjects: (callback) ->

    objects = [SFDC.CONTACT, SFDC.ACCOUNT, SFDC.OPPORTUNITY, SFDC.LEAD]

    count = objects.length
    describe = (type) ->
      SFDC.get "#{type}/describe", null, null, (err, result) ->
        if not err
          Config._setFields type, result.fields
        else
          LoggrUtil.log "Error: describe #{type} failed " + JSON.stringify(err)
        if --count is 0
          callback?()

    while objects.length > 0
      describe objects.shift()

    SFDC.get 'Task/describe', null, null, (err, result) ->
      if not err
        Config._setFields "Task", result.fields
        if result.recordTypeInfos
          Config.recordTypeInfos = result.recordTypeInfos
        for field in result.fields
          if field.name is "Type"
            if field.updateable
              LoggrUtil.log "Found updateable Task Type field"
              Config.hasTaskType = true
      else
        LoggrUtil.log "Error: describe Task failed " + JSON.stringify(err)

  # Checks if Chatter API is enabled. Tryies to retrieve the user obejct.  
  # `callback` Callback function invokde when complete.
  @checkChatterEnabled: (callback) ->
    SFDC.chatterUser (err, data) ->
      if err
        if SFDC.isChatterAPIDisabled(err)
          Config.chatterEnabled = false
        else
          LoggrUtil.log "get chatterUser failed but not due to disabled API"
      else
        LoggrUtil.log "got chatterUser so API is enabled"
      callback?()


  # `type` Contact, Account, Opportunity or Lead  
  # _return_ Array of actions enabled for the type.
  @getActions: (type) ->
    actions = []
    rowCount = 4

    getPhone = -> {id:'call', label:L.get("call"), count:rowCount++}
    getMap = -> {id:'map', label:L.get("map"), count:rowCount++}
    getEmail = -> {id:'email', label:L.get("email"), count:rowCount++}
    getCloseDate = -> {id:'close_date', label:L.get("close_date"), count:rowCount++}
    getStageName = -> {id:'stage_name', label:L.get("stage"), count:rowCount++}

    fillUpActions = ->
      # fill up row
      while actions.length < 3
        actions.push {}

    switch type

      when SFDC.ACCOUNT
      
        if Config.isFieldVisible type, "Phone"
          actions.push getPhone()

        if Config.isFieldVisible type, 'BillingCity'
          actions.push getMap()

        fillUpActions()

      when SFDC.CONTACT, SFDC.LEAD

        if Config.isFieldVisible(type, "Phone") or Config.isFieldVisible(type, "MobilePhone")
          actions.push getPhone()

        if Config.isFieldVisible type, "Email"
          actions.push getEmail()

        addressField = if type is SFDC.CONTACT then "MailingCity" else "City"
        if Config.isFieldVisible type, addressField
          actions.push getMap()

        fillUpActions()

      when SFDC.OPPORTUNITY
        ###if Config.isFieldVisible(type, "CloseDate")
          actions.push getCloseDate()

        if Config.isFieldVisible(type, "StageName")
          actions.push getStageName()###

        #fillUpActions()
      else
        LoggrUtil.log "Error: Unkown type #{type}"

    [actions: [
        {id:'checkIn', label:L.get("check-in"), count:1},
        {id:'followUp', label:L.get("follow-up"), count:2},
        {id:'takeNote', label:L.get("take_note"), count:3}
      ], {actions: actions}
    ]

  # `json` JSON representation of the Oppty record  
  # _return_ Array of stages
  @getActiveOpptyStages: (json) ->
    stageName = Config.getField SFDC.OPPORTUNITY, "StageName"
    activeStages = []
    for stage in stageName.picklistValues
      if stage.active
        stage.selected = json.StageName is stage.value
        activeStages.push stage
    return activeStages

  # `type` Contact, Account, Opportunity or Lead  
  # _return_ Array of visible fields
  @getDetailFields: (type) ->

    switch type
      when SFDC.CONTACT then fields = Config.CONTACT_FIELDS
      when SFDC.ACCOUNT then fields = Config.ACCOUNT_FIELDS
      when SFDC.OPPORTUNITY then fields = Config.OPPORTUNITY_FIELDS
      when SFDC.LEAD then fields = Config.LEAD_FIELDS
      else
        throw new Error("Unkown type #{type}")

    visibleFields = ["ID", "Name"]
    for field in fields
      if Config.isFieldVisible type, field
        visibleFields.push field
      else
        LoggrUtil.log "Warning: #{type} #{field} is invisible"
              
    LoggrUtil.log "#{type} fields " + visibleFields

    visibleFields

window?.Config = Config
module?.exports = Config