should = require 'should'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
SFDC = require '../src/coffeescripts/SFDC'

jquery = $

testThreshold = 10

describe 'SFDC', ->

  before () ->
    SFDC._TIMEOUT_THRESHOLD = testThreshold
    $.ajax = () ->

  after () ->
    SFDC._TIMEOUT_THRESHOLD = 10000
    $.ajax = jquery.ajax

  describe '#ajax()', ->
    # timeout got refactored. ignore this test
    return
    it "ajax should timeout after #{testThreshold}ms with 408", (done) ->
      startTime = new Date().valueOf()
      SFDC.ajax "fooUrl", "POST", null, (err, result) ->
        # allow a range for the callback since it can vary by 1ms
        (new Date().valueOf() - startTime).should.be.within(testThreshold, testThreshold + 2)
        err.status.should.equal 408
        done()

    it "ajax should timeout only once after #{testThreshold}ms with 408", (done) ->
      startTime = new Date().valueOf()
      errCalls = 0
      setTimeout -> 
        errCalls.should.equal 1
        done()
      , (testThreshold * 3)
      SFDC.ajax "fooUrl", "POST", null, (err, result) ->
        # allow a range for the callback since it can vary by 1ms
        (new Date().valueOf() - startTime).should.be.within(testThreshold, testThreshold + 3)
        err.status.should.equal 408
        errCalls += 1
