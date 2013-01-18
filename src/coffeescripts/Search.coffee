###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Search extends EventDispatcher

  # Event constant
  @SELECT: "search"

  # _private_ cached search result
  _cachedResult:
    data: null
    searchTerm: null
    relatedAccounts: null

  # _private_ function to invalidate the cache
  _invalidateCache: () ->
    Search.cachedResult =
      data: null
      searchTerm: null
      relatedAccounts: null

  # _private_ function to execute the search
  _executeSearch: (event) =>
    event.preventDefault()
    searchTerm = $('#search').blur().attr('value')

    @_invalidateCache()

    displayError = (message) ->
      error = '<span style="padding-left: 10px">' + message + '</span>'
      $('#searchResult').empty().append(error)

    # Ensure that user is searching with at least 2 characters
    if searchTerm.trim().length < 2
      displayError L.get("search_min_length")
      return

    $overlay = $("#overlay")

    $overlay.spin "large", "white"

    # hide potential old result right away
    $('#searchResult').empty()
    
    Settings.getObjectConfig (config) =>
      SFDC.search searchTerm, config, (err, data) =>
        $overlay.spin false

        if !err
          LoggrUtil.log 'search result ' + data.length

          if data?.length > 0
            LoggrUtil.tagEvent 'Execute search', {length:searchTerm.length, results:data.length}
            @_cachedResult = data
            @_cachedSearchTerm = searchTerm
          else
            LoggrUtil.tagEvent 'Execute search with no matches'

          if data?.length > 0

            @_cachedResult.data = data
            @_cachedResult.searchTerm = searchTerm
            # Dictionary for Account Ids mapping to Account names
            @_cachedResult.relatedAccounts = {}

            accountRelations = []
            for item in data
              type = LoggrUtil.getType(item.Id)
              if type is SFDC.CONTACT or type is SFDC.OPPORTUNITY

                if not Model.getAccountName(item.AccountId)
                  accountRelations.push item.AccountId if item.AccountId

            if accountRelations.length > 0
              SFDC.getAccountNames accountRelations, (err, result) =>
                Model.setAccountNames result.records                
                @_renderResult()
            else
              @_renderResult()

          else
            # Escape searchTerm to prevent XSS
            searchTerm = LoggrUtil.htmlEncode searchTerm
            displayError L.get("no_search_matches", searchTerm)


  # _private_ function to render the search result
  _renderResult: () ->
    data = Model.decorateAccountNames @_cachedResult.data

    searchResult = new Hogan.Template(T.search_result).render(list:data)
    $('#searchResult').empty().append(searchResult)

    $('#searchResultList').on 'touchstart', (event) ->
      if UI.tapReady
        target = UI.getClosestListItem event, '#list'
        UI.handleTouchDownState target, 'listUp', 'listPressed'

    # Attaching the event to the outer list element instead of individual list item
    # This reduces the number of event listeners on the DOM and making it more responsive.
    $('#searchResultList').hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      if UI.tapReady
        LoggrUtil.tagEvent 'Select search result'
        $('#search').blur()

        id = UI.getListItemId event, '#list'

        # Check if this contact/account has already been loaded
        # if not reset the corresponding list so the MRUs are
        # being loaded again.

        if Model.getSummaryById(id) is null
          type = LoggrUtil.getType id
          Model.invalidateSummaries type

        event.preventDefault()
        
        @dispatchEvent Search.SELECT, id

  # Shows the search view
  show: ->
    UI.selectNav 'search'

    partial =
      isRetina:UI.isRetina()
      search: L.get("search")

    $('#content').empty().append(new Hogan.Template(T.search).render(partial))
      
    $('#searchForm').bind 'submit', @_executeSearch
    $search = $("#search")

    $x = $('#x')
    $x.hammer(UI.buttonHammerOptions).on "tap", =>
      $x.hide()
      @_cachedResult.searchTerm = null
      $search.attr 'value', ""

    # hide x on Android since positioning is different
    if not Platform.isAndroid()
      $search.bind 'keyup input paste', (event) ->
        searchTerm = $search.attr 'value'

        if searchTerm.length > 0
          $x.show()
        else
          $x.hide()

    if @_cachedResult.data
      $search.attr "value", @_cachedResult.searchTerm if @_cachedResult.searchTerm
      @_renderResult()
    else
      $x.hide()

window?.Search = Search
module?.exports = Search