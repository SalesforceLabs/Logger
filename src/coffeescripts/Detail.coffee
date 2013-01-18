class Detail extends EventDispatcher

  # Event constant
  @SHOW_HASH: "showHash"

  # JSON object of the current detail record
  currentDetail: null

  # Detail iscroll instance
  detailScroller: null

  # Related list iscroll instance
  relatedListScroller: null

  # Invoke URL when invoked from another app
  invokeUrl: null

  # Action class instance
  action: null

  constructor: ->
    @action = new Action()

    # Add event listeners
    @action.addEventListener Action.REFRESH_VIEW, () =>
      @refreshView()

    @action.addEventListener Action.OPPTY_CHANGE, (json) =>
      @refreshOpptyHeader json

    # there is no document when running unit tests
    if document?
      # Ignore touchmove events when iScroll is present
      $(document).on 'touchmove', (event) =>
        if @detailScroller? || @relatedListScroller?
          event.preventDefault()

  setInvokeUrl: (@invokeUrl) ->

  resetDetailScroller: ->
    @detailScroller?.destroy()
    @detailScroller = null

  resetRelatedScroller: ->
    @relatedListScroller?.destroy()
    @relatedListScroller = null

  # Event handler to refresh detail iScroll when present
  refreshView: ->
    @detailScroller?.refresh()

    # Show a panel with related objects  
  # `list` Array of related objects
  showRelatedPanel: (list) ->
    relatedList = new Hogan.Template T.related_list
    $div = $ relatedList.render({list: list, isRetina: UI.isRetina()})

    $div.hammer(UI.buttonHammerOptions)
    .on 'touchmove', (event) ->
      # this is need in order to make iScroll work
      event.preventDefault()
    .on 'touchstart', (event) ->
      if UI.tapReady
        target = UI.getClosestListItem event, '#related_list'
        if target?
          UI.handleTouchDownState target, 'relatedListUp', 'relatedListPressed'
    .on 'tap', (event) =>
      if UI.tapReady
        #Panel.pop()
        id = UI.getListItemId event, '#related_list'
        if id
          @relatedListScroller.destroy()
          @relatedListScroller = null
          LoggrUtil.tagEvent 'Select related', {type:LoggrUtil.getType(id)}
          @dispatchEvent Detail.SHOW_HASH, "#detail?id=" + id

    Panel.show $('#app'), $div, =>
      LoggrUtil.log 'show related list'
      @relatedListScroller?.destroy()
      @relatedListScroller = new iScroll($div[0], {useTransition: true, handleClick: false})
    , =>
      history.back()
      @relatedListScroller.destroy()
      @relatedListScroller = null

  # Used from Contact & Opportunity  
  # `accountId` Account Id
  renderRelatedAccount: (accountId) =>
    $detail = $ '.detail'
    $detailContent = $detail.find('#detailContent')

    if not accountId
      $detail.find("#detailPending").spin false
    else
      cachedAccount = Model.getSummaryById accountId, (account) =>
        $detail.find("#detailPending").spin false
        $detail.find('.detailTitle').append account.Name

        # method can be called multiple times so make sure
        # the table hasn't been added yet.
        openAccount = $detailContent.find('#openAccount')
        if openAccount.length is 0
          UI.addTable $detailContent, [{label:account.Name, id:"openAccount"}], (id) =>
            if id is "openAccount" and UI.tapReady
              @dispatchEvent Detail.SHOW_HASH, "#detail?id=" + account.Id

          #refresh the scroller after adding related list drill down options.    
          @refreshView()
      if not cachedAccount
        $detail.find("#detailPending").spin "small", "white"

  # Event handler  
  # `json` Updated Oppty JSON
  refreshOpptyHeader: (json) ->
    opptyDetails = ""
    if json.CloseDate
      dates = json.CloseDate.split "-"
      # month is 0 indexed (-1)
      date = new Date(dates[0], dates[1] - 1, dates[2])
      opptyDetails += L.get("close_detail_label", date.toLocaleDateString())
    if json.CloseDate and json.StageName
      opptyDetails += " - "
    opptyDetails += json.StageName if json.StageName
    opptyDetails += '<br/>' if opptyDetails isnt ""

    $('.detailTitle').empty().append opptyDetails

    @renderRelatedAccount json.AccountId

  # `action` Action Id string
  showAction: (id) ->
    if id?.length is 0
      LoggrUtil.log 'Empty Action. Skip.'
    else
      $detailContent = $('#detailContent')
      @action.show id, $detailContent, @currentDetail, @invokeUrl
    
  # `id` Id of entity  
  # `type` Record type  
  # `name` Name of the entity
  buildDetailUI: (id, type, name) ->
    UI.tapReady = false
    detailPayload = @getDetailPayload type, name
    detailPayload.id = id
    detailPayload.isRetina = UI.isRetina()
    detail = new Hogan.Template T.detail
    $elem = $(detail.render(detailPayload))

    actionPartial = Config.getActions type
    actions = new Hogan.Template T.actions
    $elem.find('#detailContent').append(actions.render(items:actionPartial))

    Panel.show $('#app'), $elem, =>
      UI.tapReady = true
      @detailScroller?.destroy()
      @detailScroller = new iScroll($elem[0], {useTransition: true, handleClick: false, onBeforeScrollStart: null})
    , =>
      LoggrUtil.log "Close callback"
      history.back()
      @detailScroller.destroy()
      @detailScroller = null

    return $elem

  # Loads and shows related records  
  # `type` Record type  
  # `accountId` Account Id
  showRelated: (type, accountId) ->
    Model.getRelated type, accountId, (relatedObjects) =>
      @showRelatedPanel relatedObjects

  # Loads record or load from cache when available  
  # `id` Id of an Account or Contact
  show: (id) ->
    type = LoggrUtil.getType id

    # When the detail page is hit directly or a related list item is selected.
    summary = Model.getSummaryById id
    detail = Model.getDetailById id

    # There is still no entity in the cached lists when
    # the detail view is refreshed in the browser.
    if detail or summary
      # use summary name if possible which is "Lastname, Firstname"
      entity = summary or detail
      $detail = @buildDetailUI id, type, Model.getDetailName(entity)

    if not detail
      LoggrUtil.log "LoadDetail: #{type}"

      $detail?.find("#detailPending").spin "small", "white"

      SFDC.get type, id, Config.getDetailFields(type), (err, data) =>
        if !err
          LoggrUtil.log "Loaded detail"
          Model.setDetail data
          @renderDetail data, $detail
        else
          $detail?.find("#detailPending").spin false
    else
      LoggrUtil.log 'Found detail in cache.'

      # This hack is needed in order to show the transition.
      $detail?.find("#detailPending").spin "small", "white"
      setTimeout =>
        #Model.setDetail detail
        $detail?.find("#detailPending").spin false
      , 1

  # `json` Contact, Account, ...  
  # `$detail` JQuery detail div
  renderDetail: (json, $detail) ->
    @currentDetail = json
    type = LoggrUtil.getType json.Id

    LoggrUtil.tagScreen 'Detail ' + type

    if not $detail?
      name = Model.getDetailName json
      $detail = @buildDetailUI json.Id, type, name
      $detail.find("#detailPending").spin "small", "white"

    $detailContent = $detail.find('#detailContent')

    showAccountRelations = (accountId) =>

      renderTable = (options) =>
        UI.addTable $detailContent, options, (id) =>
          LoggrUtil.log "drill down #{id}"

          relatedCachedObjects = Model.getRelated id, accountId, (relatedObjects) =>
            $detail.find("#detailPending").spin false
            if relatedObjects.length > 1
              #@showRelatedPanel relatedObjects
              @dispatchEvent Detail.SHOW_HASH, "#related?accountId=#{accountId}&type=#{id}"
            else
              @dispatchEvent Detail.SHOW_HASH, "#detail?id=" + relatedObjects[0].Id

          if not relatedCachedObjects
            $detail.find("#detailPending").spin "small", "white"

        #refresh the scroller after adding related list drill down options.    
        @refreshView()

      relations = []

      # TODO refactor this logic into Model.getRelatedCount for 1.4
      # when the field is not visible just return count 0
      contactsPending = Config.hasType(SFDC.CONTACT) and Config.isFieldVisible(SFDC.CONTACT, "AccountId")
      opptyPending = Config.hasType(SFDC.OPPORTUNITY) and Config.isFieldVisible(SFDC.OPPORTUNITY, "AccountId")

      LoggrUtil.log "contactsPending #{contactsPending} / opptyPending #{opptyPending}"

      if contactsPending
        cachedContactCount = Model.getRelatedCount SFDC.CONTACT, accountId, (contactCount) =>
          contactsPending = false
          $detail.find("#detailPending").spin false
          if contactCount > 0
            relations.push {label:"Contacts (#{contactCount})", id: SFDC.CONTACT}
          renderTable relations if not opptyPending
        if cachedContactCount is -1
          $detail.find("#detailPending").spin "small", "white"

      if opptyPending
        cachedOpptyCount = Model.getRelatedCount SFDC.OPPORTUNITY, accountId, (opptyCount) =>
          opptyPending = false
          $detail.find("#detailPending").spin false
          if opptyCount > 0
            relations.push {label:"Opportunities (#{opptyCount})", id: SFDC.OPPORTUNITY}
          renderTable relations if not contactsPending
        if cachedOpptyCount is -1
          $detail.find("#detailPending").spin "small", "white"

      if not contactsPending and not opptyPending
        $detail.find("#detailPending").spin false
        
    switch type
      # Render account relations
      when SFDC.ACCOUNT
        showAccountRelations json.Id
      # Render contact relations
      when SFDC.CONTACT
        $detail.find('.detailTitle').append json.Title + '<br/>' if json.Title
        @renderRelatedAccount json.AccountId
      # Render oppoertunity relations
      when SFDC.OPPORTUNITY
        @refreshOpptyHeader json
      when SFDC.LEAD
        if json.Company
          leadDetails = ""
          leadDetails += json.Title + '<br/>' if json.Title
          leadDetails += json.Company if json.Company
          $detail.find('.detailTitle').append leadDetails
        $detail.find("#detailPending").spin false

      else $detail.find("#detailPending").spin false

    $detailAction = $detail.find '#detailAction'

    $detailAction.on 'touchstart', (event) ->
      if UI.tapReady
        target = UI.getClosestListItem event, '#detailContent'
        UI.handleTouchDownState target, 'actionUp', 'actionPressed'

    $detailAction.hammer({drag: false, transform: false, hold: false, prevent_default: true})
    .on 'tap', (event) =>
      if UI.tapReady
        actionId = UI.getListItemId event, '#detailContent'
        @showAction actionId

    if @invokeUrl
      invokeAction = @invokeUrl.action 'x-callback-url'

      switch invokeAction
        when "task"
          type = @invokeUrl.parameter('type').toLowerCase()
          LoggrUtil.log "Task type: #{type}"
          @showAction type
        when "note"
          text = @invokeUrl.parameter 'text'

      @invokeUrl = null

  # Get the detail template partial  
  # `type` Record type
  # `name` Detail name
  getDetailPayload: (type, name) ->
    detailPayload = {}

    switch type
      when SFDC.ACCOUNT
        detailPayload = {isAccount: true, name: name}
      when SFDC.CONTACT
        detailPayload = {isContact: true, name: name}
      when SFDC.OPPORTUNITY
        detailPayload = {isOpportunity: true, name: name}
      when SFDC.LEAD
        detailPayload = {isLead: true, name: name}
      else
        LoggrUtil.log 'Error: Unkown type ' + type

    return detailPayload


window?.Detail = Detail
module?.exports = Detail