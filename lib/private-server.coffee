dgram = require 'dgram'
class PrivateServer
  constructor: ->
    @services = {}
    @

  addService: (name, service) ->
    @services[name] = service

  start: (cb) ->
    @socket = dgram.createSocket "udp4"
    self = @
    services = @services
    @socket.on "message", (msg , rinfo) ->
      console.log 'okok'
      text = msg.toString "utf8"
      options = JSON.parse text
      console.log services
      console.log options.service
      console.log services[options.service]
      if services[options.service] and services[options.service][options.action]
        console.log "call #{options.service} #{options.action}"
        services[options.service][options.action] options, () ->

    @socket.bind 3001, (err) ->
      unless err?
        self.port = @address().port
        console.log "private server listen on #{self.port}"
      cb && cb err, self.port

module.exports = PrivateServer