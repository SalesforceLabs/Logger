fs     = require 'fs'
path     = require 'path'
should = require 'should'
assert = require 'assert'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
Action = require '../src/coffeescripts/Action'
global.BaseAction = require '../src/coffeescripts/BaseAction'
Task = require '../src/coffeescripts/Task'
global.SFDC = require '../src/coffeescripts/SFDC'
global.Config = require '../src/coffeescripts/Config'


describe 'Task', ->

  before ->
    L.initJSON JSON.parse(fs.readFileSync(path.resolve(__dirname,"../src/locales.json")).toString())

  describe '#getRelatedTo()', =>
    it "should return null for Contact and Lead when field is not visible", =>
      assert.equal null, Task.getRelatedTo(SFDC.CONTACT)
      assert.equal null, Task.getRelatedTo(SFDC.LEAD)

    it "should return null for Account and Opportunity when field is not visible", =>
      assert.equal null, Task.getRelatedTo(SFDC.ACCOUNT)
      assert.equal null, Task.getRelatedTo(SFDC.OPPORTUNITY)

    it "should return WhoId for Contact and Lead when field is visible", =>
      Config._setFields "Task", [{name:"WhoId"}]
      Task.getRelatedTo(SFDC.CONTACT).should.equal 'WhoId'
      Task.getRelatedTo(SFDC.LEAD).should.equal 'WhoId'
      Config._fields = {}

    it "should return WhatId for Account and Opportunity when field is visible", =>
      Config._setFields "Task", [{name:"WhatId"}]
      Task.getRelatedTo(SFDC.ACCOUNT).should.equal 'WhatId'
      Task.getRelatedTo(SFDC.OPPORTUNITY).should.equal 'WhatId'
      Config._fields = {}

  describe '#getTaskPayload()', ->
    it 'should return the correct options for checkIn', ->
      name = "John Smith"
      payload = Task.getPayload('checkIn', {Name:name})
      
      payload.should.be.a('object')

      payload.should.have.property('id', 'checkIn')
      payload.should.have.property('subject', "Visited #{name}")
      payload.should.have.property('doShowSubject', false)
      payload.should.have.property('chatterDefault', true)
      payload.should.have.property('doShowLocation', true)
      payload.should.have.property('doShowDueDate', false)
      payload.should.have.property('status', 'Completed')
      payload.should.have.property('bodyPlaceholder', 'How did the meeting go?')
      payload.should.have.property('submitLabel', 'Check-In')

    it 'should return the correct options for followUp', ->
      name = "John Smith"
      payload = Task.getPayload('followUp', {Name:name})
      
      payload.should.be.a('object')

      payload.should.have.property('id', 'followUp')
      payload.should.have.property('subject', "Follow-Up")
      payload.should.have.property('doShowSubject', true)
      payload.should.have.property('chatterDefault', false)
      payload.should.have.property('doShowLocation', false)
      payload.should.have.property('doShowDueDate', true)
      payload.should.not.have.property('status')
      payload.should.have.property('bodyPlaceholder', 'What do you need to do?')
      payload.should.have.property('submitLabel', 'Save Task')

    it 'should return the correct options for call', ->
      name = "John Smith"
      payload = Task.getPayload('call', {Name:name})
      
      payload.should.be.a('object')

      payload.should.have.property('id', 'call')
      payload.should.have.property('subject', "Call")
      payload.should.have.property('doShowSubject', false)
      payload.should.have.property('chatterDefault', false)
      payload.should.have.property('doShowLocation', false)
      payload.should.have.property('doShowDueDate', false)
      payload.should.have.property('status', 'Completed')
      payload.should.have.property('bodyPlaceholder', 'What did you talk about?')
      payload.should.have.property('submitLabel', 'Log Call')

    it 'should return the correct options for email', ->
      name = "John Smith"
      payload = Task.getPayload('email', {Name:name})
      
      payload.should.be.a('object')

      payload.should.have.property('id', 'email')
      payload.should.have.property('subject', "Email")
      payload.should.have.property('doShowSubject', false)
      payload.should.have.property('chatterDefault', false)
      payload.should.have.property('doShowLocation', false)
      payload.should.have.property('doShowDueDate', false)
      payload.should.have.property('status', 'Completed')
      payload.should.have.property('bodyPlaceholder', 'What was this message about?')
      payload.should.have.property('submitLabel', 'Log Email')
