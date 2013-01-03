{exec} = require 'child_process'
fs     = require 'fs'
assert = require 'assert'
path   = require 'path'
util   = require 'util'
growl  = require 'growl'
cs     = require 'coffee-script'
stylus = require 'stylus'
hogan  = require 'hogan.js'
compr  = require 'node-minify'

option '-c', '--config [FILE]', 'JSON config'

doWatch = false
isDev = false
config = null
client_id = process.env.LOGGER_CLIENT_ID


task 'minify', 'Minify JS to one file', ->

  new compr.minify
    type: 'yui-css',
    fileIn: 'www/main.css',
    fileOut: 'www/main.css',
    callback: (err) ->
      if err
        console.log err
      else
        console.log "compressed CSS main.css"

  addDir = (js) -> return "'www/javascripts/#{js}'"
  jsFiles = (addDir js for js in config.html.scriptTags)

  new compr.minify
    type: 'gcc',
    fileIn: jsFiles,
    fileOut: 'www/javascripts/minified-gcc.js',
    callback: (err) ->
      if err
        console.log err
      else
        console.log "compressed JavaScript: #{jsFiles}"
      for file in jsFiles
        exec "rm -rf ./#{file} ", (err, stdout, stderr) -> assert.equal err, null

getConfig = (options) ->
  if not options.config
    util.log "No JSON config specified. Use --config to specify."
    return false
  else
    config = JSON.parse fs.readFileSync("./#{options.config}").toString()
    return true

task 'build', 'Watch files for changes.', (options) ->
  if getConfig options

    invoke 'clean'

    # cleaning is not sync so wait 100ms
    setTimeout ->
      invoke 'html' if config.html
      invoke 'assets' if config.assets
      invoke 'hogan' if config.hogan
      invoke 'stylus' if config.stylus
      invoke 'coffeescript' if config.coffeescript
      invoke 'minify'
    , 2000

task 'dev', 'Watch files for changes.', (options) ->
  if client_id
    containerAuthPath = "src/coffeescripts/ContainerAuth.coffee"
    containerAuth = fs.readFileSync containerAuthPath, "utf8"
    if containerAuth.indexOf("LOGGER_CLIENT_ID") isnt -1
      containerAuth = containerAuth.replace /LOGGER_CLIENT_ID/, client_id
      fs.writeFileSync containerAuthPath, containerAuth, "utf8"
  else
    console.error "No OAuth Client Id found (env.LOGGER_CLIENT_ID). Please see the documentation on how to setup OAuth."
    return

  if getConfig options
  
    doWatch = true
    isDev= true

    invoke 'clean'
   
    # cleaning is not sync so wait 100ms
    setTimeout ->
      invoke 'html' if config.html
      invoke 'assets' if config.assets
      invoke 'hogan' if config.hogan
      invoke 'stylus' if config.stylus
      invoke 'coffeescript' if config.coffeescript

    , 1000

task 'clean', 'Remove old build artifacts', ->
  util.log 'clean'
  exec "rm -rf #{config.build} ", (err, stdout, stderr) -> assert.equal err, null
  setTimeout ->
    exec "mkdir #{config.build} ", (err, stdout, stderr) -> console.log err if err
    config.coffeescript.forEach (cfg) ->
      ###if not fs.existsSync(cfg.destination)
        fs.mkdir cfg.destination, '0777'###
      exec "mkdir #{cfg.destination}", (err, stdout, stderr) -> console.log err if err
  , 500

task 'html', 'Compile main view', (options) ->
  html = config.html

  compileHTML = () ->
    html.forEach (cfg) ->
      js = ''
      cfg.libs.forEach (lib) ->
        script = ''
        lib.jsFiles.forEach (file) ->
          if path.extname(file) is '.js'
            jsFileStr = fs.readFileSync lib.jsDir + "/" + file, "utf8"
            script += jsFileStr + '\n'
        
        fs.writeFileSync lib.jsFile, script, "utf8"
        jsLibFilename = path.basename lib.jsFile
        util.log "Write JS lib: #{jsLibFilename}"
        js += "<script src='javascripts/#{jsLibFilename}' type='text/javascript'></script>\n"

      cfg.scriptTags.forEach (scriptTag) ->
        js += "<script src='javascripts/#{scriptTag}' type='text/javascript'></script>\n"

      if not isDev
        js = "<script src='javascripts/minified-gcc.js' type='text/javascript'></script>\n"

      layoutStr = fs.readFileSync(cfg.layout).toString()
      indexStr = fs.readFileSync(cfg.index).toString()

      indexHTML = hogan.compile(layoutStr).render
          title: cfg.title
          script: js
          body: indexStr
          css: cfg.css

      util.log "Compile Index: #{cfg.filename}"
      fs.writeFileSync cfg.filename, indexHTML, "utf8"

  compileHTML()
  watch ["./" + options.config], compileHTML

task 'assets', 'Copy assets', ->
  config.assets.forEach (asset) ->
    copy asset.source, asset.destination

    if asset.watch? is true
      fs.watch asset.source, (event, filename) ->
        copy asset.source, asset.destination
        filename = path.basename asset.source
        notify "#{filename} changed", "Build complete."

task 'hogan', 'watch and compile Hogan files to JavaScript', ->
  cfg = config.hogan
  files = getFiles cfg.source, '.hogan'

  compile = () ->
    result = cfg.namespace + "={};\n"
    files.forEach (file) ->
      if path.extname(file) is '.hogan'
        contents = fs.readFileSync file, "utf8"
        util.log "Compile #{file} to #{cfg.destination}"
        temp = hogan.compile contents.toString(), {asString : true}
        filename = path.basename file, '.hogan'
        result += cfg.namespace + "." + filename + "=" + temp + "\n"

    fs.writeFileSync "#{cfg.destination}", result, "utf8"

  compile()
  watch files, compile

task 'stylus', 'watch and compile Stylus files to CSS', ->
  cfg = config.stylus

  compile = (files) ->
    files.forEach (file) ->
      if path.extname(file) is '.styl'
        stylusStr = fs.readFileSync file, "utf8"
        stylus(stylusStr).render (err, result) ->
          if not err
            filename = path.basename file, '.styl'
            filename += '.css'
            util.log "Compile #{file} to #{cfg.destination}/#{filename}"
            #fs.mkdir cfg.destination, '0777' if not fs.existsSync cfg.destination
            fs.writeFileSync "#{cfg.destination}/#{filename}", result, "utf8"
          else
            util.error err
            notify "Compile Stylus Failed.", err

  # Get files and compile initially
  files = getFiles cfg.source, '.styl'
  compile files
  watch files, compile

task 'coffeescript', 'watch and build CoffeeScript files', ->
  scripts = config.coffeescript

  scripts.forEach (cfg) ->
    compile = (files) ->
      files.forEach (file) ->
        if path.extname(file) is '.coffee'
          try
            result = cs.compile(fs.readFileSync file, "utf8")
          catch error
            notify "Compile #{file} failed.", error
          filename = path.basename file, '.coffee'
          filename += '.js'
          util.log "Compile #{file} to #{cfg.destination}/#{filename}"
          fs.writeFileSync "#{cfg.destination}/#{filename}", result, "utf8"

    # Get files and compile initially
    files = getFiles cfg.source, '.coffee'
    compile files
    watch files, compile

copy = (src, dest) ->
  util.log "Copy dir #{src} -> #{dest}"
  try
    fs.readdirSync(src).forEach (file) ->
      stat = fs.statSync src + "/" + file
      if stat.isDirectory()
        destDir = dest + "/" + file
        if not fs.existsSync(destDir)
          fs.mkdir destDir, '0777'

        copy src + "/" + file, destDir
      else
        if not fs.existsSync(dest)
          fs.mkdir dest, '0777'
        srcFile = src + '/' + file
        destFile = dest + '/' + file
        #util.log 'Copy file ' + srcFile + ' to ' + destFile
        oldFile = fs.createReadStream srcFile
        newFile = fs.createWriteStream destFile
        util.pump oldFile, newFile
  catch e
    content = fs.readFileSync src
    fs.writeFileSync dest, content, "utf8"

getFiles = (dir, extension) ->
  files = fs.readdirSync dir
  result = []
  for file in files
    do (file) ->
      currentFile = dir + '/' + file
      stats = fs.statSync currentFile
      if stats.isFile() and path.extname(currentFile) is extension
        result.push currentFile
      else if stats.isDirectory()
        return result.concat getFiles(file, extension)
  return result

watch = (files, compile) ->
  return if not doWatch
  util.log "Watching for changes in #{files}"
  for file in files then do (file) ->
    fs.watch file, (event, filename) ->
      #if +curr.mtime isnt +prev.mtime
      compile [file]
      filename = path.basename file
      notify "#{filename} changed", "Build complete."

notify = (title, message) -> 
  options = {title:title}
  growl message, options