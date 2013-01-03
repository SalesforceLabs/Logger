should = require 'should'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
SFDC = require '../src/coffeescripts/SFDC'
assert = require 'assert'

global.SFHybridApp =
  deviceIsOnline: -> true
  
describe 'SFDC', ->

  after () ->
    SFDC.setSID ''

  describe '#quoteIds()', ->
    it "should quote IDs of am array", ->
      ids = ["001abc", "001xyz"]
      SFDC.quoteIds(ids).toString().should.equal "'001abc','001xyz'"

  describe 'getAccountNameQuery()', ->
    it "should return the query containing the account IDs", ->
      ids = ["001abc", "001xyz"]
      SFDC.getAccountNameQuery(ids)
      .should.equal "SELECT Id, Name FROM Account WHERE Account.Id IN ('001abc','001xyz')"

  describe 'setContainer', ->
    it 'should be false by default', ->
      SFDC.isContainer.should.be.false
      SFDC.allowRequestQueueing.should.be.false

    it 'should be true after calling setContainer and set allowRequestQueueing to true', ->
      SFDC.setContainer(true)
      SFDC.isContainer.should.be.true
      SFDC.allowRequestQueueing.should.be.true

  describe 'setSID', ->
    it 'should set the session id', ->
      SFDC._sid.should.be.empty
      SFDC.setSID 'abc'
      SFDC._sid.should.equal 'abc'

  describe 'setInstanceUrl', ->
    it 'should set the setInstanceUrl', ->
      SFDC._instanceUrl.should.be.empty
      SFDC.setInstanceUrl 'https://na1.salesforce.com'
      SFDC._instanceUrl.should.equal 'https://na1.salesforce.com'

  describe 'isRestAPIDisabled', ->
    it 'should return if the err is a Rest API disabled error', ->
      json = {"readyState":4,"responseText":"[{\"message\":\"The REST API is not enabled for this Organization.\",\"errorCode\":\"API_DISABLED_FOR_ORG\"}]","status":403,"statusText":"Forbidden"}
      SFDC.isRestAPIDisabled(json).should.equal true

  describe 'isChatterAPIDisabled', ->
    it 'should return if the err is a API_DISABLED_FOR_ORG error', ->
      json = {"readyState":4,"responseText":"[{\"message\":\"The Chatter Connect API is not enabled for this organization or user type.\",\"errorCode\":\"API_DISABLED_FOR_ORG\"}]","status":403,"statusText":"Forbidden"}
      SFDC.isChatterAPIDisabled(json).should.equal true
    it 'should return if the err is FUNCTIONALITY_NOT_ENABLED error', ->
      json = {"readyState":4,"responseText":"[{\"message\":\"This feature is not currently enabled for this user type or org.\",\"errorCode\":\"FUNCTIONALITY_NOT_ENABLED\"}]","status":403,"statusText":"Forbidden"}
      SFDC.isChatterAPIDisabled(json).should.equal true

  describe 'isUnkownError', ->
    it 'should return if the err is a 500', ->
      json = {"readyState":4,"responseText":"[{\"message\":\"An unexpected error occurred. Please include this ErrorId if you contact support: 1678459733-112656 (-771449107)\",\"errorCode\":\"UNKNOWN_EXCEPTION\"}]","status":500,"statusText":"Internal Server Error"}
      SFDC.isUnknownError(json).should.equal true

  describe 'getMessageFromError', ->
    it 'should return the message of an error', ->
      json = {"readyState":4,"responseText":"[{\"message\":\"The requested resource does not exist\",\"errorCode\":\"NOT_FOUND\"}]","status":404,"statusText":"Not Found"}
      SFDC.getMessageFromError(json).should.equal "The requested resource does not exist\n"