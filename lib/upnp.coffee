{EventEmitter} = require 'events'
ssdp = require './ssdp'
descriptionServer = require './description-server'
http = require 'http'
async = require 'async'
utils = require './utils'
express = require 'express'


class Upnp extends EventEmitter
  constructor: (@device, @port) ->
    @device.upnp = @
    @

  start: ->
      @descriptionServer = new descriptionServer @device, @port
      @descriptionServer.start (err, port) =>
        return @emit 'error', err if err?

        utils.getNetworkIPs (err, ips) =>
          return @emit 'error', err if err?
          notificationTypes = {}

          (notificationTypes[ip] = @device.getNotificationTypes ip for ip in ips)
          @ssdp = new ssdp notificationTypes
          @ssdp.start => @emit 'ready'

  makeDescriptionUrl: (ipaddress, relativeUrl) ->
    @descriptionServer.makeDescriptionUrl ipaddress, relativeUrl

module.exports.Upnp = Upnp