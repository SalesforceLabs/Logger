###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
fs = require 'fs'
Build = require './libs/server/Build'

json = process.argv[2]
config = JSON.parse fs.readFileSync("./#{json}").toString()

if not config?
  console.error "Error: Config name #{configName} does not exist."
  return


console.log "Config: " + JSON.stringify config
console.log "Build target #{config.build}"

client_id = process.argv[3]
if client_id
  console.log "Set Client Id #{client_id}"
  containerAuthPath = "src/coffeescripts/ContainerAuth.coffee"
  containerAuth = fs.readFileSync containerAuthPath, "utf8"
  if containerAuth.indexOf("LOGGER_CLIENT_ID") isnt -1
    containerAuth = containerAuth.replace /LOGGER_CLIENT_ID/, client_id
    fs.writeFileSync containerAuthPath, containerAuth, "utf8"
else
  console.log "No OAuth Client Id found (env.LOGGER_CLIENT_ID). Please see the documentation on how to setup OAuth."

fs.mkdir config.build, '0777'
# Create javascript dir

config.coffeescript.forEach (cs) ->
  fs.mkdir cs.destination, '0777'
  Build.compileCoffeeScript cs

Build.compileStylus config.stylus
Build.compileTemplates config.hogan
config.assets.forEach (asset) -> Build.copy asset.source, asset.destination
config.html.forEach (markup) -> Build.compileHTML markup



