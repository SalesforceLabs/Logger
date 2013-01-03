should = require 'should'
assert = require 'assert'
global.LoggrUtil = require '../src/coffeescripts/LoggrUtil'
global.UI = require '../src/coffeescripts/UI'
global.Platform = require '../src/coffeescripts/Platform'
global.Action = require '../src/coffeescripts/Action'
global.EventDispatcher = require '../src/coffeescripts/EventDispatcher'
global.Search = require '../src/coffeescripts/Search'
Main = require '../src/coffeescripts/Main'

main = null

describe 'Main', ->

  @beforeEach () ->
   main = new Main()

  @afterEach () ->
    main = null

  