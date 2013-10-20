os = require 'os'

module.exports.getNetworkIP =  (cb) ->
  interfaces = os.networkInterfaces() or ''
  ip = null
  isLocal = (address) -> /(127\.0\.0\.1|::1|fe80(:1)?::1(%.*)?)$/i.test address
  ((ip = config.address) for config in info when config.family == 'IPv4' and !isLocal config.address) for name, info of interfaces
  err = if ip? then null else new Error "IP address could not be retrieved."
  cb err, ip