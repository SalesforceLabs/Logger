should = require 'should'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
Platform = require '../src/coffeescripts/Platform'

describe 'Platform', ->

  describe '#addEventListener()', ->
    it "after adding a listener it should be invoked when the event gets dispatched", (done) ->
      Platform.addEventListener 'foo', (data) ->
        data.should.equal 'bar'
        done()

      Platform.dispatchEvent 'foo', 'bar'