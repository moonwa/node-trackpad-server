ffi  = require 'ffi'
ref = require 'ref'
struct = require 'ref-struct'

kernel32 = ffi.Library 'kernel32',
  'GetLastError': [ 'int', [ ] ]

module.exports = kernel32
