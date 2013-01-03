should = require 'should'
assert = require 'assert'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
global.SFDC = require '../src/coffeescripts/SFDC'
global.T = {}
Model = require '../src/coffeescripts/Model'

describe 'Model', ->

  before () ->
    SFDC.getRelatedCount = (relatedObject, accountId, callback) ->
      callback 1

  afterEach () ->
    Model._accounts = []
    Model._contacts = []
    Model._accountsDetails = {}
    Model._contactDetails = {}
    Model._cachedRelated = {}
    Model._relatedCount = {}
    Model._lastType = SFDC.CONTACT

  describe '#getContactsCount', ->
    it 'should return -1 when not cached', ->
      assert.equal -1, Model.getRelatedCount SFDC.CONTACT, '001abc'

    it 'should return the count when cached', ->
      Model._relatedCount[SFDC.CONTACT + '001abc'] = 23
      assert.equal 23, Model.getRelatedCount SFDC.CONTACT, '001abc'

  describe '#getLastType()', ->
    it 'should be Contact initialy', ->
      Model.getLastType().should.equal SFDC.CONTACT

  describe '#setLastType()', ->
    it 'should set the last type', ->
      Model.setLastType(SFDC.ACCOUNT).should.equal SFDC.ACCOUNT
      Model.setLastType(SFDC.CONTACT).should.equal SFDC.CONTACT

  describe '#getSummaries()', ->
    it 'should be empty if not set', ->
      Model.getSummaries(SFDC.ACCOUNT).should.be.empty
      Model.getSummaries(SFDC.CONTACT).should.be.empty

  describe '#setSummaries()', ->
    it 'should cache a list of summaries', ->
      Model.setSummaries(SFDC.CONTACT, [{Id:"003", Name:"Foo, Bar"}])
      .should.have.length 1
      Model.getSummaries(SFDC.ACCOUNT)
      .should.be.empty

  describe '#getSummaryById()', ->
    it 'should return a summary when list is set', ->
      assert.equal null, Model.getSummaryById('003')
      summaries = [{Id:"003", Name:"Foo, Bar"}]
      Model.setSummaries(SFDC.CONTACT, summaries)
      .should.have.length 1
      Model.getSummaryById('003').should.exist

  describe '#getDetailById', ->
    it 'should return a cached detail', ->
      item = {Id:'001abc', Name:'Foo'}
      assert.equal null, Model.getDetailById(item.Id)
      Model.setDetail item
      Model.getDetailById(item.Id).should.exist

  describe '#addToBeginning()', ->
    it 'should add a summary to the beginning', ->
      Model.setSummaries(SFDC.ACCOUNT, [{Id:'001xyz', Name:'Bar'}])
      .should.have.length 1
      Model.addToBeginning({Id:'001abc', Name:'Foo'})
      Model.getSummaries(SFDC.ACCOUNT).should.have.length 2
      Model.getSummaryById('001abc')
      .should.be.have.property('Name', 'Foo')

  describe '#getDetailName()', ->
    it 'should return the details name based on the type', ->
      Model.getDetailName({Id:'001', Name:'Foo'}).should.equal 'Foo'
      Model.getDetailName({Id:'003', FirstName:'Foo', LastName: 'Bar'}).should.equal "Foo Bar"
    it 'should return change the order when it is Lastname, Firstname', ->
      Model.getDetailName({Id:'003', Name:'Smith, John'}).should.equal 'John Smith'

  describe '#resetCache()', ->
    it 'should reset the summaries', ->
      Model.setSummaries SFDC.ACCOUNT, [{Id:'001abc', Name:'Account'}]
      Model.resetCache()
      Model.getSummaries(SFDC.ACCOUNT).should.be.empty

    it 'should reset the account detail', ->
      Model.setDetail {Id:'001abc', name:'Account'}
      Model.resetCache()
      assert.equal null, Model.getDetailById('001abc')

    it 'should reset the contact detail', ->
      Model.setDetail {Id:'003abc', name:'John'}
      Model.resetCache()
      assert.equal null, Model.getDetailById('003abc')

    it 'should reset the cached related cache', ->
      Model._cachedRelated[SFDC.CONTACT + '001abc'] = {}
      Model.resetCache()
      assert.equal null, Model.getRelated SFDC.CONTACT, '001abc'

    it 'should reset the cached contacts count', ->
      Model._relatedCount[SFDC.CONTACT + '001abc'] = 12
      Model.resetCache()
      assert.equal -1, Model.getRelatedCount SFDC.CONTACT, '001abc'

    it 'should reset the cached opportunities', ->
      Model.setOpportunitiesForAccount('001abc' , [{Id:'006abc'}, {Id:'006xyz'}])
      Model.resetCache()
      assert.equal null, Model.getOpportunitiesForAccount('001abc')

  describe 'should cache opportunities', ->
    it 'should return null when account is not cached', ->
      assert.equal null, Model.getOpportunitiesForAccount('001abc')

    it 'should return oppties when account is cached', ->
      Model.setOpportunitiesForAccount('001abc' , [{Id:'006abc'}, {Id:'006xyz'}])
      Model.getOpportunitiesForAccount('001abc').should.have.length 2

