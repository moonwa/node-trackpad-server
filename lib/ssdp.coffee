dgram = require 'dgram'
makeUuid = require 'node-uuid'
url = require 'url'
os = require 'os'
async = require 'async'
_ = require "underscore"
http = require "http"
xml = require "xml"

{EventEmitter} = require 'events'

class ssdp extends EventEmitter
  # Address and port for broadcast messages.
  ssdpInfo:
    address: '239.255.255.250'
    port: 1900
    version:[1,0]

  ttl: 4
  timeout: 1800
  uuid: makeUuid()
  name: "Node-Upnp-Device-Host"
  httpInfo: {
    address: null
    port: null
  }
  constructor: (@_device, address = null) ->
    throw Error "devece is required" unless _device

    @broadcastSocket = dgram.createSocket 'udp4', @ssdpListener
    async.parallel
      address: (cb) => if address then cb null, address else @getNetworkIP cb
      uuid: (cb) => cb null, @uuid
      port: (cb) =>
        @httpServer = http.createServer(@httpListener)
        @httpServer.listen (err) ->
          cb err, @address().port
      (err, res) =>
        return @emit 'error', err if err?
        @_device.setUuid res.uuid
        @uuid = res.uuid
        @httpInfo.address = res.address
        @httpInfo.port = res.port
        console.log "Web server listening on http://#{@httpInfo.address}:#{@httpInfo.port}"
        @broadcastSocket.bind @ssdpInfo.port,'0.0.0.0', =>
          @broadcastSocket.addMembership @ssdpInfo.address
          @broadcastSocket.setMulticastTTL @ttl
          @announce()
          @emit 'ready'
  getNetworkIP: (cb) ->
    interfaces = os.networkInterfaces() or ''
    ip = null
    isLocal = (address) -> /(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
    ((ip = config.address) for config in info when config.family == 'IPv4' and !isLocal config.address) for name, info of interfaces
    err = if ip? then null else new Error "IP address could not be retrieved."
    cb err, ip
  announce: ()->
    @_multicast 'byebye'
    @_multicast 'alive'
    makeTimeout = => Math.floor Math.random() * ((@timeout / 2) * 1000)
    iamlive = =>
      setTimeout =>
        @_multicast('alive')
        iamlive()
      , makeTimeout()
    iamlive()

  ssdpListener: (msg, rinfo)=>
    # Wait between 0 and maxWait seconds before answering to avoid flooding
    # control points.
    answer = (address, port) =>
      messages = (@makeSsdpMessage('ok', st: st, ext: null) for st in @makeNotificationTypes())
      @send messages, address, port

    respondTo = [ 'ssdp:all', 'upnp:rootdevice', @_device, @uuid ]
    @parseRequest msg, rinfo, (err, req) ->
      if req.method is 'M-SEARCH' and req.st in respondTo
        wait = Math.floor Math.random() * (parseInt(req.mx)) * 1000
        # console.log "Replying to search request from #{address}:#{port} in #{w
        setTimeout answer, req.mx, req.address, req.port

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

  makeHttpMessage: (reqType, headers) ->
    # First line of message string.
    # We build the string as an array first for `join()` convenience.
    message =
      if reqType is 'ok'
        [ "HTTP/1.1 200 OK" ]
      else
        [ "#{reqType.toUpperCase()} * HTTP/1.1" ]

    # Add header key/value pairs.
    message.push "#{h.toUpperCase()}: #{v}" for h, v of headers

    # Add carriage returns and newlines as specified by HTTP.
    message.push '\r\n'
    new Buffer message.join '\r\n'

  makeSsdpMessage: (reqType, customHeaders) ->
    # These headers are included in all SSDP messages. Setting their value
    # to `null` makes `makeHeaders()` add default values.
    for header in [ 'cache-control', 'server', 'usn', 'location' ]
      customHeaders[header] = null
    headers = @makeHeaders customHeaders
    @makeHttpMessage reqType, headers

  makeUrl: (pathname) ->
    url.format
      protocol: 'http'
      hostname: "#{@httpInfo.address}"
      port: @httpInfo.port  #@httpPort ? @device.httpPort
      pathname: pathname

  makeHeaders: (customHeaders) ->
    # If key exists in `customHeaders` but is `null`, use these defaults.
    defaultHeaders =
      'cache-control': "max-age=#{@timeout}"
      'content-type': 'text/xml; charset="utf-8"'
      ext: ''
      host: "#{@httpInfo.address}:#{@httpInfo.port}"
      location: @makeUrl '/device/description'
      server: [
        "#{os.type()}/#{os.release()}"
        "UPnP/#{@ssdpInfo.version.join('.')}"
        "#{@name}/1.0" ].join ' '
      usn: "uuid:#{@uuid}" +
        if @uuid is (customHeaders.nt or customHeaders.st) then ''
        else '::' + (customHeaders.nt or customHeaders.st)

    headers = {}
    for header of customHeaders
      headers[header.toUpperCase()] = customHeaders[header] or defaultHeaders[header.toLowerCase()]
    headers

  send: (messages, address, port) ->
    @ssdpMessages.push { messages, address, port }

  ssdpMessages: async.queue (task, queueCb) ->
    { messages, address, port } = task
    socket = dgram.createSocket 'udp4'
    socket.bind(  =>
      async.forEach messages,
        (msg, cb) ->
          socket.send msg, 0, msg.length, port, address, cb
        (err) ->
          console.log err if err?
          socket.close()
          queueCb()
    )

  makeNotificationTypes: ->
    services = @_device.services ? []
    ['upnp:rootdevice', "uuid:#{@uuid}", @_device.getUpnpType()].concat(
      service.getUpnpType() for service in services
    )

  _multicast: (status) ->
    messages = for nt in @makeNotificationTypes()
      @makeSsdpMessage "notify", nt: nt, nts: "ssdp:#{status}", host:null
    async.forEach messages,
      (msg, cb) =>
        @broadcastSocket.send msg, 0, msg.length, @ssdpInfo.port, @ssdpInfo.address, cb
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
          service = @_device.getServiceByType(serviceType)
          service.requestHandler { action, req, id }, cb
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
      { specVersion: [ { major: @ssdpInfo.version[0] }
                       { minor: @ssdpInfo.version[1] } ] }
      { device: @_device.buildDescription() }
    ] } ]

  makeNS: (category, suffix = '') ->
    category ?= if @device? then 'service' else 'device'
    [ 'urn', ssdp.schema.domain,
      [ category, ssdp.schema.version[0], ssdp.schema.version[1] ].join '-'
    ].join(':') + suffix

ssdp.schema = { domain: 'schemas-upnp-org', version: [1,0] }
module.exports = ssdp
