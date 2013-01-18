###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Dialog

  # Flag if dialog is already open
  @isOpen: false


  # Show a alert, short handle for Dialog.show  
  # `title` Title of the dialog  
  # `body` Body text of the dialog    
  @alert: (title, body) ->
    Dialog.show title, body, L.get("ok"), null, null, false

  # Show a dialog  
  # `title` Title of the dialog  
  # `body` Body text of the dialog  
  # `submitLabel` Label of the submit button  
  # `submitCallback` Callback function called on submit  
  # `cancelCallback` Callback function called on cancel  
  @show: (title, body, submitLabel, submitCallback, cancelCallback, showCancel = true) ->
    LoggrUtil.log "show dialog"
    if not Dialog.isOpen
      Dialog.isOpen = true
      dialogDiv = new Hogan.Template T.dialog
      partial = 
        title:title
        body:body
        submitLabel:submitLabel
        cancelLabel: L.get("cancel")
        showCancel: showCancel
      $('body').append dialogDiv.render partial
      
      $overlay = $('#dialogOverlay')
      $overlay.hide().fadeIn 'fast'
      UI.alignVertically($overlay.find('#dialog'), window)

      fadeOut = ->
        kill = ->
          Dialog.isOpen = false
          $overlay.remove()

        if not Platform.isAndroid()
          $overlay.fadeOut 'fast', -> kill()
        else
          kill()

      if showCancel
        $overlay.find("#cancel").hammer(UI.buttonHammerOptions)
        .on 'tap', (event) ->
          event.preventDefault()
          fadeOut()
          cancelCallback?()
      else
        $overlay.find("#submit").css "float", "none"
        $overlay.find("footer").css "text-align", "center"

      $overlay.find("#submit").hammer(UI.buttonHammerOptions)
      .on 'tap', (event) ->
        event.preventDefault()
        submitCallback?()
        fadeOut()

      $overlay.on 'orientationchange', () ->
        UI.alignVertically($overlay.find('#dialog'), window)
    else
      LoggrUtil.log "Warning: Dialog already open. Skipping #{title}: #{body}"

window?.Dialog = Dialog
module?.exports = Dialog