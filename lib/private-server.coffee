dgram = require 'dgram'
async = require 'async'
class PrivateServer
  constructor: (@port) ->
    @services = {}
    @

  addService: (name, service) ->
    @services[name] = service

  start: (cb) ->
    @socket = dgram.createSocket "udp4"
    self = @
    services = @services
    @socket.on "message", (msg , rinfo) ->
      text = msg.toString "utf8"
      options = JSON.parse text
      if services[options.service] and services[options.service][options.action]
        services[options.service][options.action]  options, () ->

    self = @
    async.series [
      (cb) =>
        if @port
          @socket.bind @port, (err) ->
            unless err?
              self.port = @address().port
              console.log "private server listen on #{self.port}"
            cb && cb err, self.port
        else
          @socket.bind (err) ->
            unless err?
              self.port = @address().port
              console.log "private server listen on #{self.port}"
            cb && cb err, self.port
    ], (error) ->


module.exports = PrivateServer