express = require 'express'
http = require 'http'
url = require 'url'
class DescriptionServer
  constructor: (@device, { @address }) ->

  start: (cb) ->
    @app = express()
    @app.use @app.router

    @device.registerHttpHandler @app

    httpServer = http.createServer  @app
    self = @
    httpServer.listen 3000, (err) ->
      unless err?
        self.port = @address().port
        console.log "Web server listening on http://#{self.address}:#{self.port}"
      cb err, self.port

  makeDescriptionUrl: (relativeUrl) ->
    url.format
      protocol: 'http'
      hostname: @address
      port: @port
      pathname: relativeUrl

module.exports = DescriptionServer