###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Note extends BaseAction

  # Note is not private by default
  isPrivate: false

  constructor: (@json, @options, @callback) ->
    @type = LoggrUtil.getType @json.Id
    LoggrUtil.log "new Note #{@type}"

  # Render template
  render: ->
    note = new Hogan.Template T.note

    partial =
      placeholder: L.get("note_placeholder")
      cancel: L.get("cancel")
      save_note: L.get("save_note")
      private_note: L.get("private_note")

    @form = $(note.render(partial))

    $private = @form.find('#private')

    @form.find('#privateNote').hammer({drag: false, transform: false, hold: false})
    .on 'tap', (event) =>
      @isPrivate = !@isPrivate
      LoggrUtil.log 'Private note ' + @isPrivate
      $private.toggleClass "active"

    formValid = false

    $textarea = @form.find("textarea")

    @form.find('#body').bind 'keyup input paste', (event) =>
      tempNote = $textarea.attr('value')
      #LoggrUtil.log 'temp note ' + tempNote
      if tempNote.trim().length is 0 and formValid
        LoggrUtil.log 'Disable'
        formValid = false
        @form.find('#submit').toggleClass('submitButton submitButtonDisabled')
      else if tempNote.trim().length > 0 and not formValid
        LoggrUtil.log 'Enable'
        formValid = true
        @form.find('#submit').toggleClass('submitButton submitButtonDisabled')

    @initCancelButton()

    @initSubmitButton().hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      event.preventDefault()
      if formValid
        body = $textarea.attr('value')
        title = body.substring(0, 50)

        payload = 
          Title: title
          Body: body
          ParentId: @json.Id
          IsPrivate: @isPrivate 

        @disableFields true

        UI.showPending L.get("saving")

        LoggrUtil.tagEvent 'Take Note',
          type: @type
          private: @isPrivate
          bodyLength:body.length
          
        SFDC.create 'Note', payload, (err, data) =>
          UI.hidePending(err is null)
          @callback err, data
          @disableFields false if err

    return @form

window.Note = Note