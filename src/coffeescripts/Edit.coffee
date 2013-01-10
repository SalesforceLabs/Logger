###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Edit extends BaseAction

  # Edit type constants
  @PHONE: "Phone"
  @EMAIL: "Email"
  @ADDRESS: "Address"

  # Template partial
  partial: {}

  # `editType` Edit.PHONE, Edit.EMAIL or Edit.ADDRESS  
  # `json` Record object  
  # `callback` Optional callback function to handle the result (data)
  constructor: (@type, @json, @callback) ->
    LoggrUtil.log "new Edit #{@type}"
    if not @json
      throw new Error "JSON for edit not set: #{@json}"

    switch @type
      when Edit.PHONE
        @partial.message = L.get("add_number")
        @partial.phone = true
        @partial.address = false
        @partial.email = false
        @partial.showPhone = @json.Phone is null or @json.Phone is ""
        @partial.showMobile = @json.MobilePhone is null or @json.MobilePhone is ""
        @partial.phone_placeholder = L.get("phone")
        @partial.mobile_placeholder = L.get("mobile")
      when Edit.EMAIL
        @partial.message = L.get("add_email")
        @partial.phone = false
        @partial.address = false
        @partial.email = true
        @partial.email_placeholder = L.get("email")
      when Edit.ADDRESS
        @partial.message = L.get("add_address")
        @partial.address = true
        @partial.phone = false
        @partial.email = false
        @partial.street_placeholder = L.get("street")
        @partial.city_placeholder = L.get("city")
        @partial.state_placeholder = L.get("state")
        @partial.zip_placeholder = L.get("zip")
      else
        throw new Error "Unknown edit type: #{@type}."
        
    @partial.cancel = L.get("cancel")
    @partial.save = L.get("save")

  # Render template
  render: ->
    LoggrUtil.log "Render partial " + JSON.stringify(@partial)


    @form = $(new Hogan.Template(T.add).render(@partial))

    @initCancelButton()

    @initSubmitButton().hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      event.preventDefault()
      if @validate()

        LoggrUtil.tagEvent 'Update', {type: @type}

        UI.showPending L.get("saving")

        objectType = LoggrUtil.getType @json.Id
        SFDC.update objectType, @json, @payload(), (err, data) =>
          UI.hidePending(err is null)

          if not err
            for field, value of @payload()
              @json[field] = value
            @callback()
          else
            @displayErrors err         

    # Hack: Need timeout since form only gets added to the DOM
    # after the render call. Need to refactor this.
    setTimeout =>
      @validate()
    , 1

    return @form

  # Payload of the udpate call
  payload: () ->
    switch @type
      when Edit.PHONE
        payload = {}
        phone = @form.find('#phone')?.attr('value')
        payload.Phone = phone if phone
        
        mobile = @form.find('#mobile')?.attr('value')
        payload.MobilePhone = mobile if mobile

        return payload
      when Edit.EMAIL
        payload = {}
        email = @form.find('#Email').attr('value')
        payload.Email = email if email
        return payload
      when Edit.ADDRESS
        payload = {}
        street = @form.find('#street').attr('value')
        city = @form.find('#city').attr('value')
        state = @form.find('#state').attr('value')
        zip = @form.find('#zip').attr('value')

        objectType = LoggrUtil.getType @json.Id
        switch objectType
          when SFDC.CONTACT
            payload.MailingStreet = street if street
            payload.MailingCity = city if city
            payload.MailingState = state if state
            payload.MailingPostalCode = zip if zip
          when SFDC.ACCOUNT
            payload.BillingStreet = street if street
            payload.BillingCity = city if city
            payload.BillingState = state if state
            payload.BillingPostalCode = zip if zip
          when SFDC.LEAD
            payload.Street = street if street
            payload.City = city if city
            payload.State = state if state
            payload.PostalCode = zip if zip
          else
            throw new Error "Unkonwn type #{objectType}"
        return payload

  # Validate form data
  validate: () ->
    $submit = @form.find('#submit')

    toggleSubmit = (valid) ->
      if (valid and $submit.hasClass 'submitButtonDisabled') or (not valid and $submit.hasClass 'submitButton')
        $submit.toggleClass('submitButton submitButtonDisabled')

    switch @type
      when Edit.PHONE
        $phone = @form.find('#phone')
        $mobile = @form.find('#mobile')

        isValid = ->
          $phone.attr('value')?.trim().length > 0 or $mobile.attr('value')?.trim().length > 0

        formValid = isValid()

        @form.find('input').bind 'keyup', (event) =>
          formValid = isValid()
          toggleSubmit formValid
        return formValid

      when Edit.EMAIL
        $email = @form.find('#Email')

        isValid = ->
          $email.attr('value').trim().length > 0

        formValid = isValid()

        @form.find('input').bind 'keyup', (event) =>
          formValid = isValid()
          toggleSubmit formValid
        return formValid

      when Edit.ADDRESS
        $street = @form.find('#street')
        $city = @form.find('#city')

        isValid = ->
          $street.attr('value').trim().length > 0 and $city.attr('value').trim().length

        formValid = isValid()

        @form.find('input').bind 'keyup', (event) =>
          formValid = isValid()
          toggleSubmit formValid
        return formValid



window.Edit = Edit