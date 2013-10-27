express = require 'express'
http = require 'http'
url = require 'url'
class DescriptionServer
  constructor: (@device, @port) ->

  start: (cb) ->
    @app = express()
    @app.use express.bodyParser()
    @app.use @app.router

    @device.registerHttpHandler @app

    httpServer = http.createServer  @app
    self = @
    if not @port?
      httpServer.listen (err) ->
        unless err?
          self.port = @address().port
          console.log "Web server listening on port #{self.port}"
        cb err, self.port
    else
      httpServer.listen @port, (err) ->
        unless err?
          self.port = @address().port
          console.log "Web server listening on port #{self.port}"
        cb err, self.port

  makeDescriptionUrl: (ipaddress, relativeUrl) ->
    url.format
      protocol: 'http'
      hostname: ipaddress
      port: @port
      pathname: relativeUrl

module.exports = DescriptionServer