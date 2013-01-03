should = require 'should'
LoggrUtil = require '../src/coffeescripts/LoggrUtil'

# This is required for the htmlEncode test which is using JQuery.
global.$ = require "jquery"

describe 'LoggrUtil', ->

  describe '#getISODate()', ->
    it 'should format a date as ISO string', ->
      date = new Date("July 21, 2013 01:15:00")
      LoggrUtil.getISODate(date).should.equal "2013-7-21"

      date = new Date("December 21, 2013 01:15:00")
      LoggrUtil.getISODate(date).should.equal "2013-12-21"

  describe '#isDetailHash()', ->
    it "should return true for a detail hash", ->
      LoggrUtil.isDetailHash("#detail?id=77").should.be.true

    it "should return false for no detail hash", ->
      LoggrUtil.isDetailHash("#recentContacts").should.be.false

  describe 'isRelatedHash', ->
    it 'should return flag if hash is for related list', ->
      LoggrUtil.isRelatedHash("#related").should.be.true

  describe 'getQueryParams', ->
    it 'should a dict with query params', ->
      params = LoggrUtil.getQueryParams "foo#detail?param1=foo&param2=bar"
      params["param1"].should.equal 'foo'
      params["param2"].should.equal 'bar'

  describe '#getType()', ->
    it 'should return a type string for a Salesforce ID', ->
      LoggrUtil.getType('001fjksdahfk').should.equal 'Account'
      LoggrUtil.getType('003fjksdahfk').should.equal 'Contact'

    it 'should throw an error for unsupported types', ->
      (->
        LoggrUtil.getType '005fsdafads'
      ).should.throw 'LoggrUtil.getType: Unsupported prefix 005'

    it 'should throw an error for invalid input', ->
      (->
        LoggrUtil.getType 3152345
      ).should.throw 'LoggrUtil.getType: Unsupported input 3152345'

    it 'should should return null for no input', ->
      (->
        LoggrUtil.getType()
      ).should.not.exist

  describe '#htmlEncode()', ->
    it 'should html encode html entities', ->
      LoggrUtil.htmlEncode('<script>alert(1)</script>')
      .should.equal '&lt;script&gt;alert(1)&lt;/script&gt;'

  describe '#getItemById()', ->
    it 'should return the item of the list matching the id', ->
      a =[
        {Id:'001xyz'},
        {Id:'003abc'},
        {Id:'001abc'}
      ]
      LoggrUtil.getItemById(a, '001abc')
      .should.be.a('object').and.have.property('Id', '001abc')

    it 'should return null if the item is not found.', ->
      a =[
        {Id:'001xyz'},
        {Id:'003abc'},
        {Id:'001abc'}
      ]
      (->
        LoggrUtil.getItemById(a, '001ddd')
      ).should.not.exist

    it 'should return null if the list is null or empty', ->
      a =[]
      (->
        LoggrUtil.getItemById(a, '001ddd')
      ).should.not.exist

      (->
        LoggrUtil.getItemById(null, '001ddd')
      ).should.not.exist

    it 'should return null if the id is null', ->
      a =[
        {Id:'001xyz'},
        {Id:'003abc'},
        {Id:'001abc'}
      ]
      (->
        LoggrUtil.getItemById(a, null)
      ).should.not.exist
    