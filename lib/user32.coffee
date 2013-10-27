ffi  = require 'ffi'
ref = require 'ref'
struct = require 'ref-struct'

Point = struct {
  'X': 'long'
  'Y': 'long'
}
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
ScrollInfo = struct {
  'cbSize': 'uint'
  'fMask': 'uint'
  'nMin': 'int'
  'nMax': 'int'
  'nPage': 'uint'
  'nPos': 'int'
  'nTrackPos': 'int'
}

ScrollInfoPtr= ref.refType(ScrollInfo)

#console.log Object.keys (ref.sizeof)
#console.log Object.keys (ffi)
user32 = ffi.Library 'user32',
  'GetScrollInfo': [ 'int', [ 'int', 'int', ScrollInfoPtr ] ]
  'SetScrollInfo': [ 'int', [ 'int', 'int', ScrollInfoPtr, 'int' ] ]
  'GetActiveWindow': [ 'int', [ ] ]
  'GetForegroundWindow': [ 'int', [ ] ]
  'GetFocus': [ 'int', [ ] ]
  'SetCursorPos': [ 'int', [ 'int', 'int' ] ]
  'GetCursorPos': [ 'int', [ PointPtr ] ]
  'SendInput': [ 'int', [ 'uint', MouseInputPtr, 'int' ] ]

module.exports = user32
module.exports.Point = Point
module.exports.PointPtr = PointPtr
module.exports.MouseInput = MouseInput
module.exports.MouseInputPtr = MouseInputPtr
module.exports.ScrollInfo = ScrollInfo
module.exports.ScrollInfoPtr = ScrollInfoPtr