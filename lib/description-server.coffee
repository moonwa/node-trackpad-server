express = require 'express'
http = require 'http'
class DescriptionServer
  constructor: (@device, { @address }) ->

  start: (cb) ->
    @app = express()
    @app.use @app.router

    @device.registerHttpHandler @app
    httpServer = http.createServer()
    self = @
    httpServer.listen (err) ->
      unless err?
        self.port = @address().port
        console.log "Web server listening on http://#{self.address}:#{self.port}"
      cb err, self.port

module.exports = DescriptionServer