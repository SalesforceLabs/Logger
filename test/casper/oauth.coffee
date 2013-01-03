cid = process.env.LOGGER_WEB_CONSUMER_KEY
csecr = process.env.LOGGER_WEB_CONSUMER_SECRET
lserv = 'https://login.salesforce.com'
redir = 'http://localhost:4000/token'

loginUrl = (promptLogin) ->
  url = "#{lserv}/services/oauth2/authorize?response_type=code&format=json&client_id=#{cid}&redirect_uri=#{redir}&display=touch"
  url += "&prompt=login" if promptLogin
  return url

casper = require('casper').create
  verbose: true
  logLevel: "debug"
  viewportSize:
    width: 320
    height: 480

un = process.env.LOGGER_TEST_USER
pw = process.env.LOGGER_TEST_PASS

casper.start loginUrl(false), ->
  @fill "form[name='login']", {un: un, pw: pw}, true
  @click "#Login"

casper.then -> @echo "Authorization complete"

casper.run -> @echo("done").exit()