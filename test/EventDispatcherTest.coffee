should = require 'should'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
EventDispatcher = require '../src/coffeescripts/EventDispatcher'

describe 'EventDispatcher', ->

  describe '#addEventListener()', ->
    it "after adding a listener it should be invoked when the event gets dispatched", (done) ->
      ed = new EventDispatcher()
      ed.addEventListener 'foo', (data) ->
        data.should.equal 'bar'
        done()

      ed.dispatchEvent 'foo', 'bar'