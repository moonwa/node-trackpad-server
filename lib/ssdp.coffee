utils = require './utils'
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
  name: "UPnP-Device-Host"
  httpInfo: {
    address: null
    port: null
  }
  ###
    @param notificationTypes: {ip, [notification type list]}
  ###
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
    utils.getIdealNetworkIP rinfo.address, (error, ipaddress) =>
      return console.log err if error
      notificationTypes = @notificationTypes[ipaddress]
      # Wait between 0 and maxWait seconds before answering to avoid flooding
      # control points.
      answer = (address, port) =>
        messages = for nt in notificationTypes
          httpMessage.unpack "ok",
            {
              'cache-control': "max-age=#{@timeout}"
  #            date: new Date()
              ext: ''
              location: nt.descriptionUrl
              server: [
                "#{os.type()}/#{os.release()}"
                "UPnP/#{@version.join('.')}"
                "#{@name}/1.0"
              ].join ' '
              st: nt.nt
              usn: nt.usn
            }
        @send messages, address, port

      nds = (nt.nt for nt in notificationTypes)
      respondTo = [ 'ssdp:all', 'upnp:rootdevice', nds ]
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
    # get first notificationTypes
    for k, notificationTypes of @notificationTypes
      messages = for nt in notificationTypes
        httpMessage.unpack "notify",
        {
          nt: nt.nt
          usn: nt.usn
          nts: "ssdp:#{status}"
          'cache-control': "max-age=#{@timeout}"
          host: "#{ssdp.address}:#{ssdp.port}"
          location: nt.descriptionUrl
          server: [
            "#{os.type()}/#{os.release()}"
            "UPnP/#{@version.join('.')}"
            "#{@name}/1.0"
          ].join ' '
        }

      async.forEach messages,
        (msg, cb) =>
          @broadcastSocket.send msg, 0, msg.length, ssdp.port, ssdp.address, cb
        (err) -> console.log err if err?



ssdp.schema = { domain: 'schemas-upnp-org', version: [1,0] }
module.exports = ssdp
