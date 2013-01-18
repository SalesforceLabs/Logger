###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
class Call extends BaseAction

  # Constructor  
  # `json` JSON of the record  
  # `callback` Callback function invoked when canceled and selected
  constructor: (@json, @callback) ->
    @type = LoggrUtil.getType @json.Id
    LoggrUtil.log "new Call #{@type}"

  # Render template
  render: ->
    call = new Hogan.Template T.call

    list = []

    object = LoggrUtil.getType @json.Id
    
    if Config.isFieldVisible(object, "Phone")
      if @json.Phone
        list.push {name:L.get("phone_", @json.Phone), number:@json.Phone}
      else
        list.push {name:L.get("phone+"), number:""}

    if Config.isFieldVisible(object, "MobilePhone")
      if @json.MobilePhone
        list.push {name: L.get("mobile_", @json.MobilePhone), number:@json.MobilePhone}
      else
        list.push {name:L.get("mobile+"), number:""}

    list.push {name:L.get("log_without_dialing"), number:"NaN"}

    partial = 
      list:list
      choose_a_number: L.get("choose_a_number")
      cancel: L.get("cancel")

    @form = $(call.render(partial))

    @initCancelButton()

    $submit = @form.find('#submit')
    $submit.hammer(UI.buttonHammerOptions)
    .on 'tap', (event) =>
      
      number = event.currentTarget.value
 
      if number is "NaN" or number?.length > 0
        if number isnt "NaN"
          @callback "call", number
        else
          @callback "log"
      else
        @callback "edit"
        

    return @form

window?.Call = Call
module?.exports = Call