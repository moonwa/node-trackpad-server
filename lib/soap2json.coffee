{ Parser: XmlParser } = require 'xml2js'

module.exports = (app, url, service) ->
  app.post url, (req, res, next) =>
    serviceAction = /:\d#(\w+)"$/.exec(req.headers.soapaction)?[1]
    return next null unless service[serviceAction]
    (new XmlParser).parseString req.body, (err, data) =>
      service[serviceAction] data['s:Envelope']['s:Body'][0]["u:#{serviceAction}"][0], (err, data) =>


  (action, args) ->
    # Create an action element.
    (body={})["u:#{action}Response"] = _.objectToArray args,
      [ _attr: { 'xmlns:u': @makeType() } ]

    '<?xml version="1.0"?>' + xml [ 's:Envelope': [
      { _attr: {
        'xmlns:s': 'http://schemas.xmlsoap.org/soap/envelope/'
        's:encodingStyle': 'http://schemas.xmlsoap.org/soap/encoding/' } }
      { 's:Body': [ body ] }
    ] ]
