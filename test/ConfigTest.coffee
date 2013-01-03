fs     = require 'fs'
path     = require 'path'
should = require 'should'
assert = require 'assert'
global.L = require '../src/coffeescripts/L'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
global.SFDC = require '../src/coffeescripts/SFDC'
Config = require '../src/coffeescripts/Config'

describe 'Config', ->

  before ->
    L.initJSON JSON.parse(fs.readFileSync(path.resolve(__dirname,"../src/locales.json")).toString())

  describe '#setFields()', ->
    it "should set fields for object type", ->
      fields = [
        {name:"Foo"}
      ]
      Config._setFields SFDC.CONTACT, fields
      Config.isFieldVisible(SFDC.CONTACT, "Foo").should.be.true
      Config.isFieldVisible(SFDC.CONTACT, "Bar").should.be.false
      Config.isFieldVisible(SFDC.ACCOUNT, "Bar").should.be.false

      Config._fields = {}

  describe '#getDetailFields()', ->
    it "should return the detail fields based on FLS", ->
      fields = [
        {name:"AccountId"}
      ]
      Config._setFields SFDC.CONTACT, fields
      Config.getDetailFields(SFDC.CONTACT).should.have.length 3
      Config.getDetailFields(SFDC.CONTACT)[0].should.equal "ID"
      Config.getDetailFields(SFDC.CONTACT)[1].should.equal "Name"
      Config.getDetailFields(SFDC.CONTACT)[2].should.equal "AccountId"

      Config._fields = {}

  describe "#getLabel()", ->
    it "should return the correct label for an object", ->
      Config._labels[SFDC.CONTACT] = "Kontakt"
      Config.getLabel(SFDC.CONTACT).should.equal "Kontakt"
      assert.equal null, Config.getLabel(SFDC.ACCOUNT)

      Config._labels = {}

  describe "#describeGlobal", ->
    it "should set the labels, types and feedTracking values", (done) ->
      SFDC.get = (a, b, c, callback) ->
        result = {sobjects: [{name:SFDC.CONTACT, labelPlural: "Contacts", feedEnabled: true}]}
        callback null, result

      Config.describeGlobal (err) ->
        assert.equal null, err
        Config.getLabel(SFDC.CONTACT).should.equal "Contacts"
        Config.isFeedTrackingEnabled(SFDC.CONTACT).should.be.true
        Config.hasType(SFDC.CONTACT).should.be.true
        Config.hasType(SFDC.ACCOUNT).should.be.false
        done()

  describe "#checkChatterEnabled", ->
    it "should return if chatter is enabled", ->
      Config.chatterEnabled.should.be.true

      SFDC.chatterUser = (callback) ->
        callback null, {}

      Config.checkChatterEnabled()
      Config.chatterEnabled.should.be.true

      SFDC.chatterUser = (callback) ->
        callback {error:"FUNCTIONALITY_NOT_ENABLED"}

      Config.checkChatterEnabled()
      Config.chatterEnabled.should.be.false


  describe "#describeObjects", ->
    it "should set the fields for each object", (done) ->
      SFDC.get = (a, b, c, callback) ->
        if a is "Contact/describe"
          result = {fields: [name: "AccountId"]}
        else
          result = {fields: []}

        setTimeout ->
          callback null, result
        , 1

      Config.isFieldVisible(SFDC.CONTACT, "AccountId").should.be.false
      Config.describeObjects ->
        Config.isFieldVisible(SFDC.CONTACT, "AccountId").should.be.true
        Config.isFieldVisible(SFDC.OPPORTUNITY, "AccountId").should.be.false

        done()

  describe '#getActions()', ->
    it "should return static first row", ->
      partial = Config.getActions(SFDC.ACCOUNT)
      partial.should.have.length 2
      firstRow = partial[0]
      firstRow.should.be.a('object').and.have.property('actions')
      firstRow.actions.should.have.length 3
      firstRow.actions[0].should.be.a('object').and.have.property('id', 'checkIn')
      firstRow.actions[1].should.be.a('object').and.have.property('id', 'followUp')
      firstRow.actions[2].should.be.a('object').and.have.property('id', 'takeNote')

    it "should return the partial for type Account", ->
      partial = Config.getActions(SFDC.ACCOUNT)
      secondRow = partial[1]
      secondRow.should.be.a('object').and.have.property('actions')
      secondRow.actions.should.have.length 3
      phone = secondRow.actions[0]

      secondRow.actions[0].should.be.a('object').and.not.have.property('id')
      secondRow.actions[1].should.be.a('object').and.not.have.property('id')
      secondRow.actions[2].should.be.a('object').and.not.have.property('id')

    it "should return phone and map button when set in config for Account", ->
      Config._setFields SFDC.ACCOUNT, [{name:"Phone"}, {name:"BillingCity"}]
      partial = Config.getActions(SFDC.ACCOUNT)
      secondRow = partial[1]

      secondRow.actions[0].should.be.a('object').and.have.property('id', 'call')
      secondRow.actions[1].should.be.a('object').and.have.property('id', 'map')
      secondRow.actions[2].should.be.a('object').and.not.have.property('id')
      Config._fields = {}

      Config._setFields SFDC.ACCOUNT, [{name:"Phone"}]
      partial = Config.getActions(SFDC.ACCOUNT)
      secondRow = partial[1]

      secondRow.actions[0].should.be.a('object').and.have.property('id', 'call')
      secondRow.actions[1].should.be.a('object').and.not.have.property('id')
      secondRow.actions[2].should.be.a('object').and.not.have.property('id')
      Config._fields = {}

    it "should return phone, email and map button when set in config for Contact", ->
      Config._setFields SFDC.CONTACT, [{name:"Phone"}, {name:"Email"}, {name:"MailingCity"}]
      partial = Config.getActions(SFDC.CONTACT)
      secondRow = partial[1]

      secondRow.actions[0].should.be.a('object').and.have.property('id', 'call')
      secondRow.actions[1].should.be.a('object').and.have.property('id', 'email')
      secondRow.actions[2].should.be.a('object').and.have.property('id', 'map')
      Config._fields = {}

      Config._setFields SFDC.CONTACT, [{name:"MobilePhone"}, {name:"Email"}, {name:"MailingCity"}]
      partial = Config.getActions(SFDC.CONTACT)
      secondRow = partial[1]

      secondRow.actions[0].should.be.a('object').and.have.property('id', 'call')
      secondRow.actions[1].should.be.a('object').and.have.property('id', 'email')
      secondRow.actions[2].should.be.a('object').and.have.property('id', 'map')
      Config._fields = {}

    it "should return phone, email and map button when set in config for Lead", ->
      Config._setFields SFDC.LEAD, [{name:"Phone"}, {name:"Email"}, {name:"City"}]
      partial = Config.getActions(SFDC.LEAD)
      secondRow = partial[1]

      secondRow.actions[0].should.be.a('object').and.have.property('id', 'call')
      secondRow.actions[1].should.be.a('object').and.have.property('id', 'email')
      secondRow.actions[2].should.be.a('object').and.have.property('id', 'map')
      Config._fields = {}

      Config._setFields SFDC.LEAD, [{name:"MobilePhone"}, {name:"Email"}, {name:"City"}]
      partial = Config.getActions(SFDC.LEAD)
      secondRow = partial[1]

      secondRow.actions[0].should.be.a('object').and.have.property('id', 'call')
      secondRow.actions[1].should.be.a('object').and.have.property('id', 'email')
      secondRow.actions[2].should.be.a('object').and.have.property('id', 'map')
      Config._fields = {}

    it "should return no second row for Opptys", ->
      Config._setFields SFDC.OPPORTUNITY, [{name:"Phone"}, {name:"Email"}, {name:"City"}, {name:"StageName"}, {name:"CloseDate"}]
      partial = Config.getActions(SFDC.OPPORTUNITY)
      secondRow = partial[1]

      secondRow.actions[0].should.be.a('object').and.have.property('id', 'close_date')
      secondRow.actions[1].should.be.a('object').and.have.property('id', 'stage_name')
      secondRow.actions[2].should.be.a('object').and.not.have.property('id')
      Config._fields = {}

    it "should return the partial for type Account", ->
      partial = Config.getActions(SFDC.ACCOUNT)

      secondRow = partial[1]

      secondRow.actions[0].should.be.a('object').and.not.have.property('id')
      secondRow.actions[1].should.be.a('object').and.not.have.property('id')
      secondRow.actions[2].should.be.a('object').and.not.have.property('id')
