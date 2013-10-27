os = require 'os'
ssdp = require './ssdp'
makeUuid = require 'node-uuid'
xml = require 'xml'

class Device
  constructor: (@type, { @version, @services, @uuid }) ->
    @version = @version ? 1
    @services = @services ? {}
    @uuid = @uuid ? makeUuid()
    for k, service of @services
      service.name = k
      service.device = @

  version: 1
  uuid: null

  registerHttpHandler: (app) ->
    service.registerHttpHandler app for k, service of @services

    app.get @descriptionUrl, (req, res, next) =>
      console.log "request #{@descriptionUrl}"
      data = '<?xml version="1.0"?>' + xml [
        {
          root: [
            { _attr: { xmlns: 'schemas-upnp-org:device-1-0' } }
            { specVersion: [
              { major: 1 }
              { minor: 0 }
            ] }
            { device: @buildDescription() }
          ]
        } ]

      res.set 'Content-Type', 'text/xml; charset="utf-8"'
      res.send data

  getNotificationTypes: (ipaddress) ->
    throw new Error "222" unless ipaddress?
    notificationTypes = [
      {
        nt: "upnp:rootdevice"
        usn: "uuid:#{@deviceUuid}::upnp:rootdevice"
        descriptionUrl: @upnp.makeDescriptionUrl ipaddress, @descriptionUrl
      }
      {
        nt: "uuid:#{@deviceUuid}"
        usn: "uuid:#{@deviceUuid}"
        descriptionUrl: @upnp.makeDescriptionUrl ipaddress, @descriptionUrl
      }
      {
        nt: "urn:schemas-upnp-org:device:#{@type}:#{@version}"
        usn: "uuid:#{@deviceUuid}::urn:schemas-upnp-org:device:#{@type}:#{@version}"
        descriptionUrl: @upnp.makeDescriptionUrl ipaddress, @descriptionUrl
      }
    ]
    for k, service of @services
      notificationTypes = notificationTypes.concat service.getNotificationTypes ipaddress
    nt.descriptionUrl = @upnp.makeDescriptionUrl ipaddress, @descriptionUrl for nt in notificationTypes
    notificationTypes

  @property "descriptionUrl",
    get: -> "/device/#{@type}/description".toLowerCase()

  @property "deviceUuid",
    get: -> (@parentDevice ? {uuid: @uuid}).uuid

  @property "upnp",
    set: (value) ->
      @_upnp = value
      (service.upnp = value) for k, service of @services
    get: -> @_upnp

  getServices: -> v for k, v of @services

  getServiceByType: (serviceType) ->
    service = null
    (service = v) for k, v of @services when v.getServiceType() == serviceType
    service
  buildDescription: ->
    [
      { deviceType: "urn:schemas-upnp-org:device:#{@type}:#{@version}" }
      { friendlyName: "#{@type} : #{os.hostname()}".substr(0, 64) }
      { manufacturer: 'UPnP Device for Node.js' }
      { modelName: @type.substr(0, 32) }
      { modelNumber: "1.1" }
      { serialNumber: "{881B2E0B-09C9-4B01-8C81-2E41B15188C2}" }
      { UDN: "uuid:#{@uuid}" }
      { serviceList:
        ({ service: service.buildServiceElement() }) for name, service of @services
      }
    ]

module.exports = Device
