###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class BaseAction extends EventDispatcher

  # Disable inputs to prevent focus issues
  disableFields: (flag) ->
    @form.find("input").attr "disabled", flag
    @form.find("textarea").attr "disabled", flag
    @form.find("select").attr "disabled", flag

  # Displays the error message(s) in the #error div  
  # `err` AJAX error object
  displayErrors = (err) =>
    if err.status is 400
      errors = $.parseJSON(err.responseText)
    else
      errors = [ message : err.responseText ]

    $error = @form.find('#error')
    errors.forEach (error, index) =>
      $error.append (if index then '<br/>' else '') + error.message

  # Initialize cancel button with down state
  # and init callback when tapped.
  initCancelButton: ->
    $cancel = @form.find('#cancel')
    $cancel.on "touchstart", () ->
      $cancel.toggleClass('cancelButton cancelButtonDown')
    $cancel.on "touchend", () ->
      $cancel.toggleClass('cancelButtonDown cancelButton')

    $cancel.hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      @disableFields()
      @callback null
    return $cancel

  # Initialize submit button with down state
  initSubmitButton: ->
    $submit = @form.find('#submit')
    $submit.on "touchstart", () ->
      $submit.toggleClass('submitButton submitButtonDown')
    $submit.on "touchend", () ->
      $submit.toggleClass('submitButtonDown submitButton')
    return $submit

  # Since there is no transition on Android
  # disable forms for half a second to not
  # have focus right away.
  androidDelay: ->
    if Platform.isAndroid()
      @disableFields true
      setTimeout =>
        @disableFields false
      , 1000

  # Since some Android version don't have an HTML5 date picker
  # use Cordova plugin fallback.
  # `callback` Callback function (date) invoked when date is set
  androidNativeDatePicker: (callback) ->
    if Platform.isAndroid() and not Modernizr?.inputtypes.date
      LoggrUtil.log "Android native date picker"
      @form.find('.nativedatepicker').focus (event) ->
        currentField = $ @
        myNewDate = new Date() #Date.parse(currentField.val()) or 

        # Same handling for iPhone and Android
        window.plugins.datePicker.show {
            date : myNewDate,
            mode : 'date', # date or time or blank for both
            allowOldDates : true
        }, (returnDate) ->
            newDate = new Date(returnDate)
            dateAsString = LoggrUtil.getISODate newDate
            currentField.val dateAsString
            LoggrUtil.log "set new date #{dateAsString}"
            callback? newDate
            # This fixes the problem you mention at the bottom of this script with it not working a second/third time around, because it is in focus.
            currentField.blur()

window?.BaseAction = BaseAction
module?.exports = BaseAction