{EventEmitter} = require 'events'
ssdp = require './ssdp'
descriptionServer = require './description-server'
http = require 'http'
async = require 'async'
utils = require './utils'
express = require 'express'
class Upnp extends EventEmitter
  constructor: (@device, { @address }) ->
    @device.upnp = @
    @

  start: ->
    console.log "??= #{@device.notificationTypes}"
    async.parallel
      address: (cb) => if @address? then cb null, @address else utils.getNetworkIP cb
      (err, res) =>
        { address } = res
        @descriptionServer = new descriptionServer @device, { address }
        @descriptionServer.start (err, port) =>
        return @emit 'error', err if err?
        @ssdp = new ssdp @device.notificationTypes

        @ssdp.start => @emit 'ready'


module.exports.Upnp = Upnp