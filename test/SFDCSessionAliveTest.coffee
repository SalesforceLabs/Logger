should = require 'should'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
SFDC = require '../src/coffeescripts/SFDC'

xdescribe 'SFDCSessionAive', ->

  defaultWait = SFDC._MIN_WAIT_TIME

  before () ->
    SFDC._MIN_WAIT_TIME = 10
    SFDC.allowRequestQueueing = true

  after () ->
    SFDC._MIN_WAIT_TIME = defaultWait
    SFDC.allowRequestQueueing = false

  describe '#ajax()', ->
    it 'ajax should add call to requestQueue', (done) ->
      SFDC.requestQueue.should.be.empty
      SFDC.ajax "fooUrl", "POST", null, (err, result) ->
        throw new Error 'callback should not be called'
      SFDC.requestQueue.should.have.length 1

      SFDC.requestQueue[0].should.be.a 'function'

      SFDC.sessionAlive = true

      $.ajax = () ->
        setTimeout -> 
          SFDC.requestQueue.should.be.empty
          done()
        , 1
        
      SFDC.setReady true

    it 'ajax should add to requestQueue on first 401', ->
      $.ajax = (jqXHR) -> 
        jqXHR.status = 401
        jqXHR.error jqXHR
        jqXHR.complete jqXHR

      SFDC.setReady true
      SFDC.ajax '/', 'GET', {}, (err, res) ->
        err.should.not.be.null

      SFDC.requestQueue.should.have.length 1
      SFDC.requestQueue[0].should.be.a 'function'

    it 'ajax should fail with error on second 401', ->
      SFDC.setReady true #trigger replay queue
      SFDC.requestQueue.should.have.length 0

    it 'ajax should retry in 2.5sec on status 0 error and fail after', (done) ->
      startTime = new Date().valueOf()
      $.ajax = (jqXHR) -> 
        jqXHR.status = 0
        jqXHR.error jqXHR
        jqXHR.complete jqXHR

      SFDC.setReady true
      SFDC.ajax '/', 'GET', {}, (err, res) ->
        err.should.not.be.null
        SFDC.requestQueue.should.have.length 0
        (new Date().valueOf() - startTime).should.be.above(1)
        done()

      SFDC.requestQueue.should.have.length 0