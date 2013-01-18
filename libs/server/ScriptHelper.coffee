###
Copyright (c) 2013, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
coffee = require 'coffee-script'
fs = require 'fs'

class ScriptHelper

  @coffeeScriptCompiler: (file, path, index, isLast, callback) ->
    if /\.coffee/.test path
      callback coffee.compile file
    else
      callback file

  @config: (files) -> 
    js:
      route: /\/javascripts\/client.js/
      path: './public/javascripts/'
      dataType: 'javascript'
      files: files
      preManipulate:
        '^': [ScriptHelper.coffeeScriptCompiler]

  @scriptTag: (files, prod) ->
    js = ''
    if prod
      js = "<script src='javascripts/client.js' type='text/javascript'></script>"
    else
      for jsFile in files
        if /\.coffee/.test jsFile
          file = __dirname + '/../../src/coffeescripts/' + jsFile
          source = fs.readFileSync file, "ascii"
          cs = coffee.compile source
          js += '<script type="text/javascript">' + cs + '</script>\n'
        else
          js += '<script src="javascripts/'+jsFile+'"" type="text/javascript"></script>\n\t'

    return js

module.exports = ScriptHelper