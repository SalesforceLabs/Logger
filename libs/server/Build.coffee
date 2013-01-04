###
Copyright (c) 2012, salesforce.com, inc. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###
fs = require 'fs'
util = require 'util'
path = require 'path'
try
  hogan = require '/usr/local/lib/node_modules/hogan'
catch err
  hogan = require '/usr/local/lib/node_modules/hogan.js'

cs = require '/usr/local/lib/node_modules/coffee-script'
stylus = require '/usr/local/lib/node_modules/stylus'

class Build

  @compileHTML: (cfg) ->

    js = ''
    cfg.libs.forEach (lib) ->
      script = ''
      lib.jsFiles.forEach (file) ->
        if path.extname(file) is '.js'
          jsFileStr = fs.readFileSync lib.jsDir + "/" + file, "utf8"
          script += jsFileStr + '\n'
      fs.writeFileSync lib.jsFile, script, "utf8"
      jsLibFilename = path.basename lib.jsFile
      console.log "Write JS lib: #{jsLibFilename}"
      js += "<script src='javascripts/#{jsLibFilename}' type='text/javascript'></script>\n"

    cfg.scriptTags.forEach (scriptJS) ->
      console.log 'Script Tag ' + scriptJS
      js += "<script src='javascripts/#{scriptJS}' type='text/javascript'></script>\n"

    layoutStr = fs.readFileSync(cfg.layout).toString()
    indexHTML = hogan.compile(layoutStr).render
      title: cfg.title
      script: js
      body: fs.readFileSync(cfg.index).toString()
      css: cfg.css

    #console.log 'layout ' + indexHTML
    console.log '=== Compile Index ===\n' + cfg.filename
    fs.writeFileSync cfg.filename, indexHTML, "utf8"

  ###
  @param src Image source directory
  @param dest Image destination directory 
  ###
  @copy: (src, dest) ->
    console.log "Copy dir #{src} -> #{dest}"
    try
      fs.readdirSync(src).forEach (file) ->
        stat = fs.statSync src + "/" + file
        if stat.isDirectory()
          if not path.existsSync(dest)
            fs.mkdir dest, '0777'
          destDir = dest + "/" + file
          if not path.existsSync(destDir)
            console.log '\ncreate dir ' + destDir + '\n'
            fs.mkdir destDir, '0777'

          Build.copy src + "/" + file, destDir
        else
          if not path.existsSync(dest)
            fs.mkdir dest, '0777'
          srcFile = src + '/' + file
          destFile = dest + '/' + file
          #console.log 'Copy file ' + srcFile + ' to ' + destFile
          oldFile = fs.createReadStream srcFile
          newFile = fs.createWriteStream destFile
          util.pump oldFile, newFile
    catch e
      try
        content = fs.readFileSync src
        fs.writeFileSync dest, content, "utf8"
      catch e2
        console.log "Error: #{e2}"


  ###
  @param cfg Config with src, destination and namespace
  ###
  @compileTemplates: (cfg) ->
    console.log 'compileTemplates: ' + JSON.stringify(cfg)
    templates = []
    fs.readdirSync(cfg.source).forEach (file) ->
      fileParts = file.split "."
      if fileParts[fileParts.length-1] is "hogan" and fileParts.length > 1
        templates.push cfg.source + '/' + file

    result = cfg.namespace + '={};'
    current = 0
    for template in templates
      console.log 'Hogan Templates %s to %s', template, cfg.destination
      contents = fs.readFileSync template

      temp = hogan.compile contents.toString(), {asString : true}
      templateName = template.substring template.lastIndexOf('/') + 1, template.lastIndexOf('.')
      templateJS = '\n' + cfg.namespace + '.' + templateName + '=' + temp

      result += templateJS
      if ++current >= templates.length
          # TODO only write when changes and show info when unchanged
          fs.writeFileSync cfg.destination, result, "utf8"


  ###
  @param cfg Config with src and destination
  ###
  @compileCoffeeScript: (cfg) ->
    fs.readdirSync(cfg.source).forEach (file) ->
      fileParts = file.split "."
      if fileParts[fileParts.length-1] is "coffee" and fileParts.length > 1
          #console.log 'found coffeescript: %s', cfg.source + '/' + file
          coffeeStr = fs.readFileSync cfg.source + "/" + file, "utf8"
          csComp = cs.compile coffeeStr
          filename = fileParts[0] + '.js'
          console.log 'Compile CoffeeScript ' + cfg.source + '/' + file + ' to ' + cfg.destination + '/' + filename
          # TODO only write when changes and show info when unchanged
          fs.writeFileSync cfg.destination + '/' + filename, csComp, "utf8"

  @compileStylus: (cfg) ->
    fs.readdirSync(cfg.source).forEach (file) ->
      fileParts = file.split "."
      if fileParts[fileParts.length-1] is "styl" and fileParts.length > 1
        console.log 'found stylus: %s', cfg.source + '/' + file
        stylusStr = fs.readFileSync cfg.source + "/" + file, "utf8"
        stylus(stylusStr).render (err, css) ->
          filename = fileParts[0] + '.css'
          console.log '=== Stylus Stylesheet ===\n' + cfg.source + '/' + file + ' to ' + cfg.destination + '/' + filename
          # TODO only write when changes and show info when unchanged
          fs.writeFileSync cfg.destination + '/' + filename, css, "utf8"

module.exports = Build