ssdp = require './ssdp'
fs = require 'fs'
class Service
  version: 1
  type: null

  constructor: (@type, { @version }) ->
    @version = @version ? 1

  @property "notificationTypes",
    get: ->
      [
        {
          nt: "urn:schemas-upnp-org:service:#{@type}:#{@version}"
          usn: "uuid:#{@deviceUuid}::urn:schemas-upnp-org:service:#{@type}:#{@version}"
          descriptionUrl: @upnp.makeDescriptionUrl @descriptionUrl
        }
      ]

  @property "descriptionUrl",
    get: -> "/service/#{@type}/description"

  buildServiceElement: ->
    [ { serviceType: @getUpnpType() }
      { eventSubURL: "/service/#{@type}/event" }
      { controlURL: "/service/#{@type}/control" }
      { SCPDURL: "/service/#{@type}/description" }
      { serviceId: "urn:upnp-org:serviceId:#{@_name}" } ]

  requestHandler: (args, cb) =>
    { action, req } = args
    { method } = req

    switch action
      when 'description'
        # Service descriptions are static files.
        fs.readFile("#{@serviceDescription}", 'utf8', cb)

      when 'control'
        serviceAction = /:\d#(\w+)"$/.exec(req.headers.soapaction)?[1]
        # Service control messages are `POST` requests.
        return cb new HttpError 405 if method isnt 'POST' or not serviceAction?
        data = ''
        req.on 'data', (chunk) -> data += chunk
        req.on 'end', =>
          @action serviceAction, data, (err, soapResponse) ->
            cb err, soapResponse, ext: null

      when 'event'
        {sid, timeout, callback: urls} = req.headers
        if method is 'SUBSCRIBE'
          if urls?
            # New subscription.
            if /<http/.test urls
              resp = @subscribe urls.slice(1, -1), timeout
            else
              err = new HttpError(412)
          else if sid?
            # `sid` is subscription ID, so this is a renewal request.
            resp = @renew sid, timeout
          else
            err = new HttpError 400
          err ?= new HttpError(412) unless resp?
          cb err, null, resp

        else if method is 'UNSUBSCRIBE'
          @unsubscribe sid if sid?
          # Unsubscription response is simply `200 OK`.
          cb (if sid? then null else new HttpError 412)

        else
          cb new HttpError 405

      else
        cb new HttpError 404



  getUpnpType: ->
    return [ 'urn',
             ssdp.schema.domain,
             'service',
             @type,
             @version
    ].join( ':')

module.exports = Service