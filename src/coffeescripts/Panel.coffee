###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

# Static class to add/remove and slide in/out panels.
class Panel
  
  # List of panels
  @panels: []

  # Flag if dragging is enabled or not.
  @draggingEnabled: true

  # Show panel  
  # `$app` JQuery app container  
  # `$div` JQuery div to attach and slide in  
  # `closeCallback` Function to be called when panel has been dragged out
  @show: ($app, $div, showCallback, closeCallback) ->
    # LoggrUtil.log "showPanel"
    Panel.panels.push $div

    if not Platform.isAndroid()
      UI.tapReady = false
      $div.css
        visibility: 'hidden'
        webkitTransitionProperty: 'none'
        webkitTransform: 'translate3d(100%, 0, 0)'
      .on 'webkitTransitionEnd', ->
        $div.off 'webkitTransitionEnd'
        UI.tapReady = true
        showCallback?()

    $app.append $div

    if not Platform.isAndroid()
      Panel.attachDragEvents $div, closeCallback
      
      setTimeout ->
        $div.css '-webkit-backface-visibility', 'hidden'
        $div.css '-webkit-transition-duration', '300ms'
        $div.css '-webkit-transition-timing-function', 'ease-out'
        $div.css
          visibility: ''
          webkitTransitionProperty: '-webkit-transform'
          webkitTransform: 'translate3d(0%, 0, 0)'
      , 10
    else
      $div.css
        webkitTransitionProperty: 'none'
        webkitTransform: 'translate3d(0%, 0, 0)'
      showCallback?()

  # Slides out and removes the most recent panel.
  # _return_ Flag if panel has been removed or false when there are no panels.
  @pop: (callback) ->
    if Panel.panels.length == 0 then return false

    $div = Panel.panels.pop()

    if not Platform.isAndroid()
      $div.on 'webkitTransitionEnd', ->
        $div.off().hide()
        setTimeout ->
          # LoggrUtil.log 'remove div'
          $div.remove()
          callback?()
        , 0
      .css
        webkitTransitionProperty: '-webkit-transform'
        webkitTransform: 'translate3d(100%, 0, 0)'
    else
      $div.remove()
      callback?()


    return true

  # `$div` JQuery div to add drag event listeners  
  # `closeCallback` Function to be called when panel has been dragged out
  @attachDragEvents: ($div, closeCallback) ->
    dragging = false
    dragDistX = 0

    watchDrag = ->
      if Panel.draggingEnabled and dragging
        if dragDistX > 0
          $div.css 'webkitTransform', 'translate3d(' + dragDistX + 'px, 0, 0)'
        setTimeout watchDrag, 10
    
    $div.hammer({drag_vertical: false, transform: false, tap: false, hold: false})
    .on 'dragstart', (event) ->
      # LoggrUtil.log 'dragStart ' + Panel.draggingEnabled
      if Panel.draggingEnabled
        dragging = true
        dragDistX = event.distanceX
        $div.css 'webkitTransitionProperty', 'none'
        setTimeout watchDrag, 10
    .on 'drag', (event) ->
      if dragging then dragDistX = event.distanceX
    .on 'dragend', (event) ->
      if Panel.draggingEnabled and dragging
        dragging = false
        if event.distance > 100 and event.direction == 'right'
          # LoggrUtil.tagEvent 'Close Panel'
          closeCallback()
        else
          $div.css
            webkitTransitionProperty: '-webkit-transform'
            webkitTransform: 'translate3d(0%, 0, 0)'


window.Panel = Panel