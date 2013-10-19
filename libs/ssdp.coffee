dgram = require 'dgram'
makeUuid = require 'node-uuid'
url = require 'url'
os = require 'os'
async = require 'async'
_ = require "underscore"
http = require "http"

{EventEmitter} = require 'events'

class ssdp extends EventEmitter
  # Address and port for broadcast messages.
  address: '239.255.255.250'
  port: 1900
  timeout: 1800
  ttl: 4
  uuid: makeUuid()
  name: "Upnp-Device-Host"
  constructor: ->
    @broadcastSocket = dgram.createSocket 'udp4', @ssdpListener
    @broadcastSocket.bind @port,'0.0.0.0', =>
      @broadcastSocket.addMembership @address
      @broadcastSocket.setMulticastTTL @ttl
      @emit 'ready'
  announce: (device)->
    @multicast 'byebye', device
    @multicast 'alive', device


  ssdpListener: ()->
    # Wait between 0 and maxWait seconds before answering to avoid flooding
    # control points.
    answer = (address, port) =>
      @ssdpSend(@makeSsdpMessage('ok',
        st: st, ext: null
      ) for st in @makeNotificationTypes()
        address
        port)

    respondTo = [ 'ssdp:all', 'upnp:rootdevice', @makeType(), @uuid ]
    @parseRequest msg, rinfo, (err, req) ->
      if req.method is 'M-SEARCH' and req.st in respondTo
        wait = Math.floor Math.random() * (parseInt(maxWait)) * 1000
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
      delete customHeaders[header]
    headers = @makeHeaders customHeaders
    @makeHttpMessage reqType, headers
  makeUrl: (pathname) ->
    url.format
      protocol: 'http'
      hostname: @address ? @device.address
      port: 999 #@httpPort ? @device.httpPort
      pathname: pathname
  makeHeaders: (customHeaders) ->
    # If key exists in `customHeaders` but is `null`, use these defaults.
    defaultHeaders =
      'cache-control': "max-age=#{@timeout}"
      'content-type': 'text/xml; charset="utf-8"'
      ext: ''
      host: "#{@address}:#{@port}"
      location: @makeUrl '/device/description'
      server: [
        "#{os.type()}/#{os.release()}"
        "UPnP/1.0"
        "#{@name}/1.0" ].join ' '
      usn: "uuid:#{@uuid}" +
      if "uuid:#{@uuid}" is (customHeaders.nt or customHeaders.st) then ''
      else '::' + (customHeaders.nt or customHeaders.st)

    customHeaders = _.extend defaultHeaders, customHeaders
    headers = {}
    for header of customHeaders
      headers[header.toUpperCase()] = customHeaders[header]
    headers
  ssdpMessages: async.queue (task, queueCb) ->
    { messages, address, port } = task
    socket = dgram.createSocket 'udp4'
    socket.bind()
    async.forEach messages,
      (msg, cb) -> socket.send msg, 0, msg.length, port, address, cb
      (err) ->
        console.log err if err?
        socket.close()
        queueCb()
  makeType: (entity, isService) ->
    [ 'urn'
      entity.domain ? 'schemas-upnp-org'
      if isService then 'service' else 'device'
      entity.name
      entity.version ? 1
    ].join ':'
  multicast: (status, device) ->
    services = device.services ? []
    console.log services
    console.log device
    nts = ['upnp:rootdevice', "uuid:#{@uuid}", @makeType(device)].concat(
      (@makeType service, true) for service in services
    )
    messages = for nt in nts
      @makeSsdpMessage "notify", nt: nt, nts: "ssdp:#{status}"
    async.forEach messages,
      (msg, cb) => @broadcastSocket.send msg, 0, msg.length, @port, @address, cb
      (err) -> console.log err if err?

module.exports = ssdp
