should = require 'should'
assert = require 'assert'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
global.EventDispatcher = require '../src/coffeescripts/EventDispatcher'
Detail = require '../src/coffeescripts/Detail'
global.SFDC = require '../src/coffeescripts/SFDC'
global.Config = require '../src/coffeescripts/Config'


describe 'Detail', ->

  describe '#getDetailPayload()', ->
    it "should return the right payload for each type", ->
      detail = new Detail()
      detail.getDetailPayload(SFDC.CONTACT, "Foo").should.exist

      detail.getDetailPayload(SFDC.CONTACT, "Foo")
      .should.be.a('object').and.have.property('name', 'Foo')

      detail.getDetailPayload(SFDC.CONTACT, "Foo")
      .should.be.a('object').and.have.property('isContact', true)

      detail.getDetailPayload(SFDC.ACCOUNT, "Bar")
      .should.be.a('object').and.have.property('name', 'Bar')

      detail.getDetailPayload(SFDC.ACCOUNT, "Bar")
      .should.be.a('object').and.have.property('isAccount', true)