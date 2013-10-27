os = require 'os'
_ = require 'underscore'

module.exports.getNetworkIPs =  (cb) ->
  interfaces = os.networkInterfaces() or ''
  isLocal = (address) -> /(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
  ips = ((config.address for config in info when config.family == 'IPv4' and !isLocal config.address) for name, info of interfaces)
  cb null, _.flatten ips
#
#module.exports.getNetworkIP =  (cb) ->
#  interfaces = os.networkInterfaces() or ''
#  ip = null
#  isLocal = (address) -> /(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
#  ((ip = config.address) for config in info when config.family == 'IPv4' and !isLocal config.address) for name, info of interfaces
#  err = if ip? then null else new Error "IP address could not be retrieved."
#  cb err, ip
#
module.exports.getIdealNetworkIP = (ipaddress, cb) ->
  match = (x, y) ->
    x = x.split '.'
    y = y.split '.'
    for i in [0..3]
      return i unless x[i] == y[i]
    return 3;

  interfaces = os.networkInterfaces() or ''
  isLocal = (address) -> /(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
  ips = ((({ip: config.address, matchValue: match(ipaddress, config.address)}) for config in info when config.family == 'IPv4' and !isLocal config.address) for name, info of interfaces)
  ips = _.flatten ips
  idealIpAddress = null
  (idealIpAddress = ip) for ip in ips when not idealIpAddress? or idealIpAddress.matchValue < ip.matchValue
  cb new Error "IP address could not be retrieved." if not idealIpAddress?
  cb null, idealIpAddress.ip