###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class OpptyEdit extends BaseAction

  constructor: (@json, @options, @callback) ->
    LoggrUtil.log "new OpptyEdit"

  # Render template
  render: ->
    template = new Hogan.Template T.oppty_edit
    @options.cancel = L.get("cancel")
    @options.update = L.get("update")
    @form = $(template.render(@options))

    @androidNativeDatePicker()
    @androidDelay()

    formValid = false

    if @options.showCloseDate
      $closeDate = @form.find '#closeDate'
      $closeDate.bind 'keyup input paste', (event) =>
        closeDate = $closeDate.attr 'value'

        if not formValid
          formValid = true
          @form.find('#submit').toggleClass('submitButton submitButtonDisabled')

        if closeDate is ''
          formValid = false
          @form.find('#submit').toggleClass('submitButton submitButtonDisabled')
    else if @options.showStageName
      $stage = @form.find '#stage'
      $stage.change (event) =>
        stageName = $stage.find('option:selected').attr('id')

        hasChanged = stageName isnt @json.StageName
        LoggrUtil.log "Changed stage #{stageName}: #{hasChanged}"

        if (not formValid and hasChanged) or (formValid and not hasChanged)
          formValid = hasChanged
          @form.find('#submit').toggleClass('submitButton submitButtonDisabled')

    else
      LoggrUtil.log "Error: Unsupported oppty edit options #{JSON.stringify(@options)}"  

    @initCancelButton()

    @initSubmitButton().hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      event.preventDefault()

      if formValid
        LoggrUtil.log 'submit'

        payload = {}

        if @options.showCloseDate
          $closeDate = @form.find '#closeDate'
          date = $closeDate.attr 'value'
          LoggrUtil.log "Update close date to #{date}"
          payload.CloseDate = date
        else if @options.showStageName
          $stage = @form.find '#stage'
          stageName = $stage.find('option:selected').attr('id')
          payload.StageName = stageName

        UI.showPending L.get("saving")

        LoggrUtil.tagEvent 'Edit Oppty',
          type: SFDC.OPPORTUNITY
          task: "Edit"

        SFDC.update SFDC.OPPORTUNITY, @json, payload, (err, data) =>
          UI.hidePending(err is null)

          if not err
            for field, value of payload
              @json[field] = value

            @callback @json
          else
            @displayErrors err

    return @form


window.OpptyEdit = OpptyEdit