module.exports.unpack = (reqType, headers) ->
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