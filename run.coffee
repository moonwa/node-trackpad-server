upnp = require './lib/upnp'
Device = require './lib/device'
Service = require './lib/service'

class MyDevice extends Device
  constructor: ->
    super('RemoteControl', {
      version: 1,
#      uuid: 'd2af1bd6-09d6-4669-8fc4-c04ccc4ffd8b',
      uuid: '63af7043-7b8d-45e5-9702-2ed9b3fef45b',
      services: {
        "RemoteMouse": new RemoteMouseService()
      }
    })

class RemoteMouseService extends Service
  constructor:  ->
    super('RemoteMouse', {version: 1})
  serviceDescription: "#{__dirname}/RemoteMouse.xml"

  Move: (options, next) ->
    console.log "move invoked"
    console.log options.OffsetX[0]
    ffi  = require 'ffi'
    ref = require 'ref'
    struct = require 'ref-struct'

    Point = struct {
      'X': 'long'
      'Y': 'long'
    }

    PointPtr= ref.refType(Point);
    user32 = ffi.Library 'user32',
      'SetCursorPos': [ 'int', [ 'int', 'int' ] ]
      'GetCursorPos': [ 'int', [ PointPtr ] ]
    point = new Point()
    user32.GetCursorPos point.ref()
    console.log point.X
    console.log point.Y
    user32.SetCursorPos point.X + parseInt(options.OffsetX[0]), point.Y + parseInt(options.OffsetY[0])
    next null, {}


ssdpServer = new upnp.Upnp(new MyDevice(), {address: "192.168.10.101"});
ssdpServer.on "error", (err) ->
  console.log err
ssdpServer.start();
