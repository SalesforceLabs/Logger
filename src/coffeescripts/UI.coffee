###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class UI

  # Default Hammer.js button options
  @buttonHammerOptions: {drag: false, transform: false, hold: false}

  # Flag if app is available to listen to tap events.  
  # Marking it false prevents the multiple simulataneous tap events
  @tapReady = true

  # Counter for how often the DOM was refreshed.
  # Hack for webkit scrolling bugs.
  @domRefreshCount = 0

  # Get the closest item of a clicked list  
  # `event` List click event  
  # `listId` Id of the list
  @getClosestListItem: (event, listId) ->
    target = event.originalEvent.target
    target = $(target).closest 'li', $(listId)
    return target[0]

  # Gets the item Id of a clicked list  
  # `event` List click event  
  # `listId` Id of the list
  @getListItemId: (event, listId) ->
    target = UI.getClosestListItem event, listId
    return if target then target.id else null

  # _return_ Flag if screen is a retina display
  @isRetina: -> window?.devicePixelRatio >= 2

  # After touchstart has been detectwd use this method to handle the
  # down state and reset again back to up state after move or touchend  
  # listItem List item HTML element  
  # classNameUp CSS classname for the up-state  
  # classNamePressed CSS classname for the pressed-state
  @handleTouchDownState: (listItem, classNameUp, classNamePressed) ->
    
    #return if Platform.isAndroid()

    hasReachedThreshold = false

    getName = (newName) ->
      a = listItem.className.split " "
      if a.length is 2
        return a[0] + " " + newName
      return newName

    timer = setTimeout ->
      hasReachedThreshold = true
      listItem.className = getName classNamePressed
    , 150

    clear = ->
      clearTimeout timer
      listItem.className = getName classNameUp
      removeListeners()

    touchMoveHandler = (event) -> clear()
    touchEndHandler = (event) ->
      # user has selected item so show pressed state
      # event though timer is below threshold
      if not hasReachedThreshold
        listItem.className = getName classNamePressed
        timerUp = setTimeout ->
          clear()
        , 1000
      else
        clear()
      
    removeListeners = ->
      listItem.removeEventListener 'touchmove', touchMoveHandler, false
      listItem.removeEventListener 'touchend', touchEndHandler, false

    listItem.addEventListener 'touchmove', touchMoveHandler, false
    listItem.addEventListener 'touchend', touchEndHandler, false

  @currentNav = null

  # Set the navigation styles  
  # `id` Id of the navigation to select
  @selectNav: (id) ->

    if id is UI.currentNav
      return
    else
      @currentNav = id
      
    LoggrUtil.log 'selectNav ' + id
    LoggrUtil.tagScreen 'Navigation ' + id

    navbg = if UI.isRetina() then "images/nav/navbg@2x.png" else "images/nav/navbg.png"
    navbgSelected = if UI.isRetina() then "images/nav/navbg_selected@2x.png" else "images/nav/navbg_selected.png"

    $recentNav = $("#recentNav")
    $searchNav = $("#searchNav")
    $settingsNav = $("#settingsNav")

    switch id
      when 'recent'
        $recentNav.css 'background', "url('#{navbgSelected}')"
        $recentNav.css 'border-right', "solid #06243A 1px"

        $searchNav.css 'background', "url('#{navbg}')"
        $searchNav.css 'border-left', "solid #85BDDB 1px"
        $searchNav.css 'border-right', "solid #06243A 1px"

        $settingsNav.css 'background', "url('#{navbg}')"
        $settingsNav.css 'border-left', "solid #85BDDB 1px"

      when 'search'
        $recentNav.css 'background', "url('#{navbg}')"
        $recentNav.css 'border-right', "solid #85BDDB 1px"

        $searchNav.css 'background', "url('#{navbgSelected}')"
        $searchNav.css 'border-left', "solid #06243A 1px"
        $searchNav.css 'border-right', "solid #06243A 1px"

        $settingsNav.css 'background', "url('#{navbg}')"
        $settingsNav.css 'border-left', "solid #85BDDB 1px"
      when 'settings'
        $recentNav.css 'background', "url('#{navbg}')"
        $recentNav.css 'border-right', "solid #06243A 1px"

        $searchNav.css 'background', "url('#{navbg}')"
        $searchNav.css 'border-left', "solid #85BDDB 1px"
        $searchNav.css 'border-right', "solid #85BDDB 1px"

        $settingsNav.css 'background', "url('#{navbgSelected}')"
        $settingsNav.css 'border-left', "solid #06243A 1px"
      else
        LoggrUtil.log 'Error: Unkown nav id ' + id

  # Shows model view
  @showModal: (modalInfo, callback) ->
    modalScroller = null
    $('body').append(new Hogan.Template(T.settings_modal).render(modalInfo))
    $('body .modal #closeButton').hammer(UI.buttonHammerOptions)
    .on 'tap', (event) ->
      modalScroller.destroy()
      $('body .modal').remove()
      callback?()
      
    # Attach iscroll after 10ms to ensure the dom has been updated and iscroll can calculate dimensions properly.
    setTimeout ->
      modalScroller = new iScroll($('body .modal .content')[0], {useTransition: true, handleClick: false})
    , 10

  # Shows the pending overlay  
  # `label` Label for the pending overlay
  @showPending: (label) ->
    $overlay = $ "#overlay"
    $overlay.append new Hogan.Template(T.pending).render {label: label}
    setTimeout ->
      $("#pending").spin "large", "white"
      $overlay.css "pointer-events", "auto"
    , 10

  # Hides the pending overlay  
  # `success` Flag if the operation was successful  
  # `message` Message to show before hiding the overlay
  @hidePending: (success, message) ->
    $pending = $ "#pending"
    $pending.spin false
    # NOTE: the timeout needs to be higher than
    # the showPending delay (10ms) since in the
    # offline case the error occurs right away.
    timeout = 15
    if success
      $("#pending > label").text(message || L.get("saved"))
      imgUrl = if UI.isRetina() then "pending_over@2x" else "pending_over"
      $pending.append '<img width="40" height="40" src="images/'+imgUrl+'.png" />'
      timeout = 700

    setTimeout ->
      $("#overlay").css "pointer-events", "none"
      if not Platform.isAndroid()
        $("#pendingOverlay").fadeOut 'fast', -> $("#pendingOverlay").remove()
      else
        $("#pendingOverlay").remove()
    , timeout

  # Detach and reattach dom elements inside the app div to fix scrolling issues.
  @refreshDOM: ->
    # LoggrUtil.log 'refreshDOM'
    $('#app #home').detach().appendTo('#app')
    UI.domRefreshCount += 1

  # Adds the drill down button and returns it.  
  # `$div` JQuery div  
  # `options` Array of table items  
  # `callback` Callback function (id)
  @addTable: ($div, options, callback) ->
    drillDown = new Hogan.Template T.drill_down
    $div.append drillDown.render({options:options, isRetina: UI.isRetina()})

    $tableList = $div.find("#tableList")
    $tableList.on 'touchstart', (event) ->
      target = UI.getClosestListItem event, '#list'
      UI.handleTouchDownState target, 'tableListUp', 'tableListPressed'

    $tableList.hammer(UI.buttonHammerOptions)
    .on 'tap', (event) ->
      if UI.tapReady
        target = UI.getClosestListItem event, '#tableList'
        callback target.id

  # Helper function to vertically align an element
  @alignVertically = (elem, parent) ->
    $elem = $(elem)
    $parent = $(parent)
    $elem.offset(
      top: ($parent.height()/2 - $elem.outerHeight()/2)
    )

window?.UI = UI
module?.exports = UI