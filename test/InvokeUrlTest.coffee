should = require 'should'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
InvokeUrl = require '../src/coffeescripts/InvokeUrl'

describe 'InvokeUrl', ->

  describe '#action()', ->
    it "returns the action of the url", ->
      new InvokeUrl("loggr://x-callback-url/task?id=0033000001CfIWWAA3&type=Checkin&text=foo&Completed=true&x-cancel=foo://bar&x-success=bar://foo")
      .action("x-callback-url").should.equal 'task'

    it "returns null if the host of the action is not found", ->
      (->
          new InvokeUrl("loggr://x-callback-url/task?type=Checkin").action('foo')
      ).should.not.exist

    it "returns null if this host is not set", ->
      (->
          new InvokeUrl("loggr://x-callback-url/task?type=Checkin").action()
      ).should.not.exist

    it 'returns the parameter value for a given name', ->
      invokeUrl = new InvokeUrl "loggr://x-callback-url/task?id=0033000001CfIWWAA3&type=Checkin&text=foo&Completed=true"

      invokeUrl.parameter('type').should.equal 'Checkin'
      invokeUrl.parameter('Completed').should.equal 'true'
      invokeUrl.parameter('id').should.equal  '0033000001CfIWWAA3'

    it 'parameters are not cases sensitive', ->
      invokeUrl = new InvokeUrl "loggr://x-callback-url/task?type=Checkin&text=foo&Completed=true"
      
      invokeUrl.parameter('completed').should.equal 'true'
      invokeUrl.parameter('Completed').should.equal 'true'

    it 'parameters not found should return null', ->
      invokeUrl = new InvokeUrl "loggr://x-callback-url/task?type=Checkin"
      (->
          invokeUrl.parameter('completed')
      ).should.not.exist

    it 'xSource should return the source when present', ->
      invokeUrl = new InvokeUrl "loggr://x-callback-url/task?x-source=Chatter"
      invokeUrl.xSource().should.equal 'Chatter'
      invokeUrl = new InvokeUrl "loggr://x-callback-url/task"
      (->
          invokeUrl.xSource()
      ).should.not.exist
      invokeUrl = new InvokeUrl "loggr://x-callback-url/task?foo=bar"
      (->
          invokeUrl.xSource()
      ).should.not.exist

    it 'xSuccess should return the success url when present', ->
      new InvokeUrl("loggr://x-callback-url/task?x-success=chatter://chatter/update?foo=bar")
      .xSuccess().should.equal 'chatter://chatter/update?foo=bar'

    it 'xCancel should return the cancel url when present', ->
      new InvokeUrl("loggr://x-callback-url/task?x-cancel=chatter://chatter/update?foo=bar")
      .xCancel().should.equal 'chatter://chatter/update?foo=bar'

    it 'xError should return the error url when present', ->
      new InvokeUrl("loggr://x-callback-url/task?x-error=chatter://chatter/update?foo=bar")
      .xError().should.equal 'chatter://chatter/update?foo=bar'