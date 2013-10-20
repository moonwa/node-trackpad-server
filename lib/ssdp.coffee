dgram = require 'dgram'
url = require 'url'
os = require 'os'
async = require 'async'
_ = require "underscore"
http = require "http"
xml = require "xml"
httpMessage = require "./http-message"

{EventEmitter} = require 'events'

class ssdp extends EventEmitter
  # Address and port for broadcast messages.
  version:[1,0]
  ssdp.address = '239.255.255.250'
  ssdp.port = 1900 
  ttl: 4
  timeout: 1800
  name: "Node-Upnp-Device-Host"
  httpInfo: {
    address: null
    port: null
  }
  constructor: (@notificationTypes) ->
    throw Error "notificationTypes is required" unless @notificationTypes


  start: ->
    @broadcastSocket = dgram.createSocket 'udp4', @ssdpListener
    @broadcastSocket.bind ssdp.port, '0.0.0.0', =>
      @broadcastSocket.addMembership ssdp.address
      @broadcastSocket.setMulticastTTL @ttl
      @announce()

  announce: ()->
    @_multicastStatus 'byebye'
    @_multicastStatus 'alive'
    makeTimeout = => Math.floor Math.random() * ((@timeout / 2) * 1000)
    iamlive = =>
      setTimeout =>
        @_multicastStatus('alive')
        iamlive()
      , makeTimeout()
    iamlive()

  ssdpListener: (msg, rinfo)=>
    # Wait between 0 and maxWait seconds before answering to avoid flooding
    # control points.
    answer = (address, port) =>
      messages = (@makeSsdpMessage('ok', st: st, ext: null) for st in notificationTypes)
      @send messages, address, port

#    respondTo = [ 'ssdp:all', 'upnp:rootdevice', @_device ]
#    @parseRequest msg, rinfo, (err, req) ->
#      if req.method is 'M-SEARCH' and req.st in respondTo
#        wait = Math.floor Math.random() * (parseInt(req.mx)) * 1000
#        # console.log "Replying to search request from #{address}:#{port} in #{w
#        setTimeout answer, req.mx, req.address, req.port

  parseRequest: (msg, rinfo, cb) ->
    # `http.parsers` is not documented and not guaranteed to be stable.
    parser = http.parsers.alloc()
    parser.reinitialize 'request'
    parser.socket = {}
    parser.onIncoming = (req) ->
      http.parsers.free parser
      { method, headers: { mx, st, nt, nts, usn } } = req
      { address, port } = rinfo
      cb null, { method, mx, st, nt, nts, usn, address, port }
    parser.execute msg, 0, msg.length

  makeUrl: (pathname) ->
    url.format
      protocol: 'http'
      hostname: "#{@httpInfo.address}"
      port: @httpInfo.port  #@httpPort ? @device.httpPort
      pathname: pathname

    headers = {}
    for header of customHeaders
      headers[header.toUpperCase()] = customHeaders[header] or defaultHeaders[header.toLowerCase()]
    headers

  send: (messages, address, port) ->
    @ssdpMessages.push { messages, address, port }

  ssdpMessages: async.queue (task, queueCb) ->
    { messages, address, port } = task
    socket = dgram.createSocket 'udp4'
    socket.bind(1900,  =>
      async.forEach messages,
        (msg, cb) ->
          socket.send msg, 0, msg.length, port, address, cb
        (err) ->
          console.log err if err?
          socket.close()
          queueCb()
    )


  _multicastStatus: (status) ->
    messages = for nt in @notificationTypes
      httpMessage.unpack "notify",
        nt: nt.nt
        usn: nt.usn
        nts: "ssdp:#{status}"
        'cache-control': "max-age=#{@timeout}"
        host: "#{@httpInfo.address}:#{@httpInfo.port}"
        location: nt.descriptionUrl
        server: [
          "#{os.type()}/#{os.release()}"
          "UPnP/#{@version.join('.')}"
          "#{@name}/1.0"
        ].join ' '
    async.forEach messages,
      (msg, cb) =>
        @broadcastSocket.send msg, 0, msg.length, ssdp.port, ssdp.address, cb
      (err) -> console.log err if err?


  # HTTP request listener
  httpListener: (req, res) =>
    # console.log "#{req.url} requested by #{req.headers['user-agent']} at #{req.client.remoteAddress}."

    # HTTP request handler.
    handler = (req, cb) =>
      # URLs are like `/device|service/action/[serviceType]`.
      [category, serviceType, action, id] = req.url.split('/')[1..]

      switch category
        when 'device'
          cb null, @buildDescription()
        when 'service'
#          service = @_device.getServiceByType(serviceType)
#          service.requestHandler { action, req, id }, cb
        else
          cb 404

    handler req, (err, data, headers) =>
      if err?
        # See UDA for error details.
        console.log "Responded with #{http.STATUS_CODES[err]}: #{err.message} for #{req.url}."
        res.writeHead err.toString(), 'Content-Type': 'text/plain'
        res.write "#{err.code} - #{err.message}"

      else
        # Make a header object for response.
        # `null` means use `makeHeaders` function's default value.
        headers ?= {}
        headers['server'] ?= null
        if data?
          headers['Content-Type'] ?= null
          headers['Content-Length'] ?= Buffer.byteLength(data)

        res.writeHead 200, @makeHeaders headers
        res.write data if data?

      res.end()

  buildDescription: ->
    '<?xml version="1.0"?>' + xml [ { root: [
      { _attr: { xmlns: @makeNS() } }
      { specVersion: [ { major: @version[0] }
                       { minor: @version[1] } ] }
      { device: @_device.buildDescription() }
    ] } ]
ssdp.schema = { domain: 'schemas-upnp-org', version: [1,0] }
module.exports = ssdp

# If key exists in `customHeaders` but is `null`, use these defaults.
#defaultHeaders =
#  'cache-control': "max-age=#{@timeout}"
#  'content-type': 'text/xml; charset="utf-8"'
#  ext: ''
#  host: "#{@httpInfo.address}:#{@httpInfo.port}"
#  location: @makeUrl '/device/description'
#  server: [
#    "#{os.type()}/#{os.release()}"
#    "UPnP/#{@version.join('.')}"
#    "#{@name}/1.0" ].join ' '
#  usn: "uuid:#{@uuid}" +
#  if @uuid is (customHeaders.nt or customHeaders.st) then ''
#  else '::' + (customHeaders.nt or customHeaders.st)