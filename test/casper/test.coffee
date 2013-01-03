casper = require('casper').create
  verbose: true
  logLevel: "info"
  viewportSize:
    width: 320
    height: 480

un = process.env.LOGGER_TEST_USER
pw = process.env.LOGGER_TEST_PASS

# Accept Eula
casper.start "http://localhost:4000", ->
  @click "#closeButton"

# Show Login
casper.then ->
  @click ".signinButton"

# Trigger OAUth
casper.then ->
  @fill "form[name='login']", {un: un, pw: pw}, true
  @click ".loginButton"

casper.then ->
  @captureSelector 'temp/main.png', '#home'
  @mouseEvent "touchstart", "#searchNav"

casper.wait 500, ->
  @captureSelector 'temp/search.png', '#home'
  #@fill "form[name='searchForm']", {q: "Foo"}, true

###casper.thenEvaluate (term) ->
    #document.querySelector('form[name="searchForm"]').submit()
, { term: 'Foo' }

casper.wait 100, ->
  @captureSelector 'temp/search_foo.png', '#home'###

casper.then ->
  #@debugHTML()
  @mouseEvent "touchstart", "#settingsNav"

casper.wait 500, ->
  @captureSelector 'temp/settings.png', '#home'

casper.then ->
  @mouseEvent "touchstart",  "#recentNav"

casper.then ->
  @mouseEvent "touchstart",  "#Accounts"

casper.then ->
  @mouseEvent "touchstart",  "#Contacts"
  @mouseEvent "tap",  ".listUp"

casper.wait 1000, ->
   @echo "waited for drill down"

casper.then ->
  @captureSelector 'temp/detail.png', '#home'

casper.run ->
  # display results
  @echo("done").exit()