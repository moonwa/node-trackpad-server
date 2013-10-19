os = require 'os'
ssdp = require './ssdp'
class Device
  constructor: (@_type, @_version = 1) ->
    @_services = @createServices()
    (service._name = k) for k, service of @_services

  _version: 1
  _name: null
  _services: []
  _uuid: null

  setUuid: (@_uuid) ->
  getServiceByType: (serviceType) ->
    service = null
    (service = v) for k, v of @_services when v.getServiceType() == serviceType
    service
  buildDescription: ->
    [
      { deviceType: @getUpnpType() }
      { friendlyName: "#{@name} @ #{os.hostname()}".substr(0, 64) }
      { manufacturer: 'UPnP Device for Node.js' }
      { modelName: @_type.substr(0, 32) }
      { UDN: "uuid:#{@_uuid}" }
      { serviceList:
        ({ service: service.buildServiceElement() }) for name, service of @_services
      }
    ]
  getUpnpType: ->
    return [ 'urn',
             ssdp.schema.domain,
             'device',
             @_type,
             @_version
    ].join( ':')
module.exports = Device
