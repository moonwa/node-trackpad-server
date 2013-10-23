{ Parser: XmlParser } = require 'xml2js'
_ = require "underscore"
xml = require "xml"

_.mixin objectToArray: (obj, arr = []) ->
  throw new TypeError("Not an object.") unless _.isObject obj
  Object.keys(obj).map (key) ->
    o = {}
    o[key] = obj[key]
    arr.push o
  arr

module.exports = (app, url, service, ns) ->
  console.log "regisster service '#{url}'"
  app.post url, (req, res, next) =>
    data = ''
    req.setEncoding 'utf8'
    req.on 'data', (chunk) =>
      data += chunk

    req.on 'end', =>
      serviceAction = /:\d#(\w+)"$/.exec(req.headers.soapaction)?[1]
      console.log "invoke action #{serviceAction}"
      return next null unless service[serviceAction]
      console.log data
      (new XmlParser).parseString data, (err, data) =>
        service[serviceAction] data['s:Envelope']['s:Body'][0]["u:#{serviceAction}"][0], (err, data) =>
          return next err if err
          # Create an action element.
          (body={})["u:#{serviceAction}Response"] = _.objectToArray data,
            [ _attr: { 'xmlns:u': ns } ]

          result = '<?xml version="1.0"?>' + xml [ 's:Envelope': [
            { _attr: {
              'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
              's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/' } }
            { 's:Body': [ body ] }
          ] ]
          console.log "result = #{result}"
          res.send result
