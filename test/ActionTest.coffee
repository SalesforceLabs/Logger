should = require 'should'
assert = require 'assert'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
global.EventDispatcher = require '../src/coffeescripts/EventDispatcher'
Action = require '../src/coffeescripts/Action'
global.SFDC = require '../src/coffeescripts/SFDC'
global.Config = require '../src/coffeescripts/Config'


describe 'Action', ->

  