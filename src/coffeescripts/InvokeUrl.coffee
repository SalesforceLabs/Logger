###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###

# Specs: [x-callback-url specs](http://x-callback-url.com/specifications)
class InvokeUrl

  # `url` URL structure [scheme]://[host]/[action]?[x-callback parameters]&[action parameters]
  constructor: (@url) ->

  # The remaining portion of the URL path after the version make up
  # the name of the action to be executed in the target app. These
  # actions will vary by app and should be documented by the developer
  # of the app supporting x-callback-url.
  #
  # `host` URLs will be identified by the use of “x-callback-url” as
  # the host portion of the URL.
  action: (host) ->
    if host
      patt = new RegExp "#{host}/(\\w*)\?"
      match = patt.exec @url
      return match[1]
    return null

  # `name` Name of the parameter
  # returns the value of the matching parameter or null if not found.
  parameter: (name) ->
    if name.indexOf '?' > 0
      name = name.toLowerCase()
      parameters = ""
      parts = @url.split('?')
      length = parts.length
      for part, i in parts
        parameters += part if i > 0
        parameters += '?' if i > 0 and i < length - 1

      parameters = parameters.split '&'
      for param in parameters
        paramParts = param.split('=')
        if paramParts[0].toLowerCase() is name
          result = ""
          for paramPart, j in paramParts
            result += paramPart if j > 0
            result += '=' if j > 0 and j < length - 1
          return result

    return null

  # The friendly name of the source app calling the action. If the
  # action in the target app requires user interface elements, it
  # may be necessary to identify to the user the app requesting the
  # action.
  xSource: -> @parameter 'x-source'

  # If the action in the target method is intended to return
  # a result to the source app, the x-callback parameter should
  # be included and provide a URL to open to return to the
  # source app. On completion of the action, the target app will
  # open this URL, possibly with additional parameters tacked on
  # to return a result to the source app. If x-success is not
  # provided, it is assumed that the user will stay in the target
  # app on successful completion of the action.
  xSuccess: -> @parameter 'x-success'

  # URL to open if the requested action is cancelled by the user.
  # In the case where the target app offer the user the option to
  # “cancel” the requested action, without a success or error result,
  # this the the URL that should be opened to return the user to the
  # source app.
  xCancel: -> @parameter 'x-cancel'

  # URL to open if the requested action generates an error in the
  # target app. This URL will be open with at least the parameters
  # “errorCode=code&errorMessage=message. If x-error is not present,
  # and a error occurs, it is assumed the target app will report the
  # failure to the user and remain in the target app.
  xError: -> @parameter 'x-error'


window?.InvokeUrl = InvokeUrl
module?.exports = InvokeUrl