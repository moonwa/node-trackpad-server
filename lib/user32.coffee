ffi  = require 'ffi'
ref = require 'ref'
struct = require 'ref-struct'

Point = struct {
  'X': 'long'
  'Y': 'long'
}
PointPtr= ref.refType(Point)
PointPtr= ref.refType(Point)
MouseInput = struct {
  'type': 'int'
  'dx': 'long'
  'dy': 'long'
  'mouseData': 'int'
  'dwFlags': 'int'
  'time': 'int'
  'dwExtraInfo': 'int'
}
MouseInputPtr = ref.refType(MouseInput)
KeyBdInput = struct {
  'type': 'int'
  'wVk' : 'int16'
  'wScan': 'int16'
  'dwFlags': 'int'
  'time': 'int'
  'dwExtraInfo': 'long'
  'placeholder': 'int64'
}
KeyBdInputPtr = ref.refType(KeyBdInput)
#console.log Object.keys (ref.sizeof)
#console.log Object.keys (ffi)
user32 = ffi.Library 'user32',
  'SetCursorPos': [ 'int', [ 'int', 'int' ] ]
  'GetCursorPos': [ 'int', [ PointPtr ] ]
  'SendInput': [ 'int', [ 'uint', MouseInputPtr, 'int' ] ]

module.exports = user32
module.exports.Point = Point
module.exports.PointPtr = PointPtr
module.exports.MouseInput = MouseInput
module.exports.MouseInputPtr = MouseInputPtr
module.exports.KeyBdInput = KeyBdInput
module.exports.KeyBdInputPtr = KeyBdInputPtr