os = require 'os'
ssdp = require './ssdp'
makeUuid = require 'node-uuid'

class Device
  constructor: (@type, { @version, @services }) ->
    @version = @version ? 1
    @services = @services ? {}
    for k, service of @services
      service.name = k
      service.device = @

  version: 1
  uuid: null

  registerHttpHandler: (app) ->
#    app.get @descriptionUrl,

  @property "notificationTypes",
    get: =>
      notificationTypes = [
        {
          nt: "upnp:rootdevice"
          usn: "uuid:#{@deviceUuid}::upnp:rootdevice"
        }
        {
          nt: "uuid:#{@deviceUuid}"
          usn: "uuid:#{@deviceUuid}"
        }
        {
          nt: "urn:schemas-upnp-org:device:#{@type}:@version"
          usn: "uuid:#{@deviceUuid}::urn:schemas-upnp-org:device:#{@type}:@version"
        }
      ]
      for k, service of @services
        notificationTypes = notificationTypes.concat service.notificationTypes
      notificationTypes

  @property "descriptionUrl", =>
    get: -> "/device/#{@type}/description"

  @property "deviceUuid",
    get: => (@parentDevice ? {uuid: @uuid}).uuid

  @property "upnp",
    set: (value) =>
      @_upnp = value
      (service.upnp = value) for k, service of @services

  getServices: -> v for k, v of @services
  setUuid: (@_uuid) ->
  getServiceByType: (serviceType) ->
    service = null
    (service = v) for k, v of @services when v.getServiceType() == serviceType
    service
  buildDescription: ->
    [
      { deviceType: @getUpnpType() }
      { friendlyName: "#{@type} @ #{os.hostname()}".substr(0, 64) }
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
