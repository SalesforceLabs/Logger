###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Model

  #@defaultRecordType = null

  # application scope for records (JSON)
  @_contacts = []
  @_accounts = []
  @_opportunities = []
  @_leads = []

  # Map of cached related accounts/contacts lists.
  @_cachedRelated = {}

  # application scope for record details
  @_accountDetails = {}
  @_contactDetails = {}
  @_opportunityDetails = {}
  @_leadDetails = {}

  # _private_ remember last type (Contact or Account) for navigation
  @_lastType = SFDC.CONTACT

  # _return_ Last selected record type
  @getLastType: -> return Model._lastType

  # Set last selected record type  
  # `type` Record type
  @setLastType: (type) -> Model._lastType = type

  # Dictionary where key is AccountId and value the name
  @_accountNames: {}

  # Store account names  
  # `records` Array of JSON with Account Id/Name
  @setAccountNames: (records) ->
    for account in records
      Model._accountNames[account.Id] = account.Name

  # Returns Account name by id  
  # `accountId` Id of the Account
  @getAccountName: (accountId) ->
    Model._accountNames[accountId]

  # adds the accountName field when already cached  
  # `item` Item of type Contact or Opportunity
  @addAccountName: (item) ->
    type = LoggrUtil.getType(item.Id)
    if type is SFDC.CONTACT or type is SFDC.OPPORTUNITY
      # this is no boolean expression but an intended assignment
      if accountName = Model._accountNames[item.AccountId]
        item.accountName = accountName
    return item

  # `items` List of contacts or opptys
  @decorateAccountNames: (items) ->
    data = (Model.addAccountName item for item in items)
    return data

  # _private_ cache the count of related contacts for the drill down button
  @_relatedCount = {}

  # Gets the related count  
  # `relatedObject` Contact or Opportunity  
  # `accountId` Account Id  
  # `callback` Callback function (count)
  @getRelatedCount: (relatedObject, accountId, callback) ->
    key = relatedObject + accountId
    count = if Model._relatedCount[key]? then Model._relatedCount[key] else -1
    #LoggrUtil.log "getRelatedCount for key #{key}: #{count}"

    if count isnt -1
      callback?(count)
    else
      SFDC.getRelatedCount relatedObject, accountId, (err, data) ->
        if not err
          LoggrUtil.log "#{data.totalSize} related #{relatedObject}(s)"
          count = data.totalSize
          Model._relatedCount[key] = count
          callback?(count)
    return count

  # _private_ cache of opportunities for an account
  @_opportunitiesForAccount = {}

  # `accountId` Account Id
  @getOpportunitiesForAccount: (accountId) -> return Model._opportunitiesForAccount[accountId]

  # `accountId` Account Id
  # `opportunities` Array of opportunities
  @setOpportunitiesForAccount: (accountId, opportunities) -> Model._opportunitiesForAccount[accountId] = opportunities

  # _private_ detail cache  
  # `type` Record type
  @_getDetailCache: (type) ->
    switch type
      when SFDC.ACCOUNT
        cache = Model._accountDetails
      when SFDC.CONTACT
        cache = Model._contactDetails
      when SFDC.OPPORTUNITY
        cache = Model._opportunityDetails
      when SFDC.LEAD
        cache = Model._leadDetails
      else
        throw new Error 'Error: Unkown type ' + type
    return cache

  # Resets all cache
  @resetCache: ->
    Model._contacts = []
    Model._accounts = []
    Model._opportunities = []
    Model._leads = []
    Model._opportunitiesForAccount = {}
    Model._cachedRelated = {}
    Model._contactsCount = {}
    Model._accountDetails = {}
    Model._contactDetails = {}
    Model._opportunityDetails = {}
    Model._leadDetails = {}
    Model._relatedCount = {}

  # Get related objects  
  # `relatedObject` Record type  
  # `id` Record Id  
  # `callback` Callback function (relateddObjects)
  @getRelated: (relatedObject, id, callback) ->
    key = relatedObject + id
    related = Model._cachedRelated[key]
    LoggrUtil.log  "getRelated #{key}: #{related}"

    if not related and callback
      SFDC.getRelated relatedObject, id, (err, data) ->
        if !err
          LoggrUtil.log "Loadeded related #{relatedObject}(s) (#{data.records.length})"
          related = data.records
          Model._cachedRelated[key] = related
          callback?(related)
    else
      callback?(related)

    return related

  # Get maps query  
  # `json` Record object
  @getGeoQuery: (json) ->
    type = LoggrUtil.getType json.Id
    query = null
    if type is SFDC.CONTACT
      if json.MailingStreet and json.MailingCity
        query = 'q=' + json.MailingStreet + ', ' + json.MailingCity
        query += ', ' + json.MailingState if json.MailingState
        query += ' ' + json.MailingPostalCode if json.MailingPostalCode
    else if type is SFDC.ACCOUNT
      if json.BillingStreet and json.BillingCity
        query = 'q=' + json.BillingStreet + ', ' + json.BillingCity
        query += ', ' + json.BillingState if json.BillingState
        query += ' ' + json.BillingPostalCode if json.BillingPostalCode
    else if type is SFDC.LEAD
      if json.Street and json.City
        query = 'q=' + json.Street + ', ' + json.City
        query += ', ' + json.State if json.State
        query += ' ' + json.PostalCode if json.PostalCode
    return query

  # Cache record MRUs  
  # `type` Record type  
  # `list` Array of records
  @setSummaries: (type, list) ->
    switch type
      when SFDC.ACCOUNT
        Model._accounts = list
      when SFDC.CONTACT
        Model._contacts = list
      when SFDC.OPPORTUNITY
        Model._opportunities = list
      when SFDC.LEAD
        Model._leads = list
      else
        throw new Error 'Error: Unkown type ' + type
    return list

  # Adds a new MRU summary to the top  
  # `summary` MRU summary
  @addToBeginning: (summary) ->
    type = LoggrUtil.getType summary.Id
    console.log 'addToBeginning ' + summary.Id
    switch type
      when SFDC.ACCOUNT
        Model._accounts.unshift summary
      when SFDC.CONTACT
        Model._contacts.unshift summary
      when SFDC.OPPORTUNITY
        Model._opportunities.unshift summary
      when SFDC.LEAD
        Model._leads.unshift summary
      else
        throw new Error 'Error: Unkown type ' + type

  # Format detail name  
  # `json` Record object
  @getDetailName: (json) ->
    type = LoggrUtil.getType json.Id
    switch type
      when SFDC.ACCOUNT, SFDC.OPPORTUNITY, SFDC.LEAD
        return json.Name
      when SFDC.CONTACT
        if json.LastName and json.FirstName
          return json.FirstName + " " + json.LastName
        else if json.Name
          a = json.Name.split ', '
          if a?.length is 2
            return a[1] + " " + a[0]
          return json.Name
        else
          return "Error: Name not found."
      else
        throw new Error 'Error: Unkown type ' + type

  # Clear MRU cache  
  # `type` Record type
  @invalidateSummaries: (type) ->
    switch type
      when SFDC.ACCOUNT
        Model._accounts = []
      when SFDC.CONTACT
        Model._contacts = []
      when SFDC.OPPORTUNITY
        Model._opportunities = []
      when SFDC.LEAD
        Model._leads = []
      else
        throw new Error 'Error: Unkown type ' + type

  # Get list of cached MRUs  
  # `type` Record type
  @getSummaries: (type) ->
    switch type
      when SFDC.ACCOUNT
        list = Model._accounts
      when SFDC.CONTACT
        list = Model._contacts
      when SFDC.OPPORTUNITY
        list = Model._opportunities
      when SFDC.LEAD
        list = Model._leads
      else
        throw new Error 'Error: Unkown type ' + type
    return list

  # Get template partial  
  # `type` Record type  
  # `list` Array of records
  @getSummariesPartial: (type, list) ->
    partial =
      list: list
      isAccount: type is SFDC.ACCOUNT
      isContact: type is SFDC.CONTACT
      isOpportunity: type is SFDC.OPPORTUNITY
      isLead: type is SFDC.LEAD
      isEmpty: list.length is 0

  # `id` Id to look up
  # _return_ item matching the id or null when not found
  @getSummaryById: (id, callback) ->
    type = LoggrUtil.getType id
    item = LoggrUtil.getItemById Model.getSummaries(type), id
    if item
      callback?(item)
    else
      item = Model.getDetailById id
      if item
        callback?(item)
      else if callback
        SFDC.get type, id, Config.getDetailFields(type), (err, data) ->
          if !err
            LoggrUtil.log "Loaded related #{type}"
            Model.setDetail data
            callback?(data)
    return item

  # `id` Detail Id
  @getDetailById: (id) ->
    type = LoggrUtil.getType id
    return Model._getDetailCache(type)[id]

  # `item` Detail record
  @setDetail: (item) ->
    cache = Model._getDetailCache LoggrUtil.getType(item.Id)
    cache[item.Id] = item
 

window?.Model = Model
module?.exports = Model