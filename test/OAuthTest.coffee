should = require 'should'
OAuth = require '../libs/server/OAuth'

describe 'OAuth', ->

  before (next) ->

    port = 4000
    cid = process.env.CLIENT_ID or '3MVG99OxTyEMCQ3gAfa.1ZqJK.nSpkB3WJFCU8qc1eFfHp8IqmszpTykRpDCCV8fmZQ_8asm1W1e361CUN.DA'
    csecr = process.env.CLIENT_SECRET or '2636319206044415665'
    lserv = process.env.LOGIN_SERVER or 'https://login.salesforce.com'
    redir = process.env.REDIRECT_URI or 'http://localhost:' + port + '/token'

    @auth = new OAuth
      clientId: cid
      clientSecret: csecr
      loginServer: lserv
      redirectUri: redir

    # for async setup
    next()

  describe '#loginUrl()', ->
    it 'should return a valid login URL', ->
      @auth.loginUrl(false).should.equal 'https://login.salesforce.com/services/oauth2/authorize?response_type=code&format=json&client_id=3MVG99OxTyEMCQ3gAfa.1ZqJK.nSpkB3WJFCU8qc1eFfHp8IqmszpTykRpDCCV8fmZQ_8asm1W1e361CUN.DA&redirect_uri=http://localhost:4000/token&display=touch'

    it 'should return a valid login URL forcing the prompt', ->
      @auth.loginUrl(true).should.equal 'https://login.salesforce.com/services/oauth2/authorize?response_type=code&format=json&client_id=3MVG99OxTyEMCQ3gAfa.1ZqJK.nSpkB3WJFCU8qc1eFfHp8IqmszpTykRpDCCV8fmZQ_8asm1W1e361CUN.DA&redirect_uri=http://localhost:4000/token&display=touch&prompt=login'

  
  ###describe '#logout()', ->
    it 'should be status 400 when you try to logout an invalid sid', (done) ->
      req = {session:{sid:'invalid sid'}}
      @auth.logout req, (err) ->
        err.statusCode.should.equal 400
        done()###

  describe '#encrypt()/#decrypt()', ->
    it 'should have the same value after encrypting and decrypting', ->
      token = "489217358972138947120984713920847"
      encrypted = OAuth.encrypt token
      encrypted.should.not.equal token
      OAuth.decrypt(encrypted).should.equal token
      OAuth.should.have.property('algorithm', 'aes256')
      should.exist OAuth.key
  