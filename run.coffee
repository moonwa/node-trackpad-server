upnp = require './lib/upnp'
Device = require './lib/device'
Service = require './lib/service'
PrivateServer = require './lib/private-server'
user32 = require './lib/user32'
kernel32 = require './lib/kernel32'
utils = require './lib/utils'
ffi = require 'ffi'
ref = require 'ref'
os = require 'os'


class RemoteMouseService
  moveOffset: ( options, next) ->
    try
      console.log "move invoked x = #{options.offsetX}, y = #{options.offsetY}"

      point = new user32.Point()
      user32.GetCursorPos point.ref()
      user32.SetCursorPos point.X + options.offsetX, point.Y + options.offsetY
      next null, {}
    catch ex
      next null, ex

  leftDown: ( options, next) ->
    try
      mouseInput = new user32.MouseInput()
      mouseInput.type = 0
      mouseInput.dx = 0
      mouseInput.dy = 0
      mouseInput.mouseData = 0
      mouseInput.dwFlags =0x0002
      mouseInput.time = 0
      mouseInput.dwExtraInfo = 0
      user32.SendInput 1, mouseInput.ref(), 28
      next null, {}
    catch ex
      console.log "ex=#{ex}"
      next null, ex
  leftUp: (options, next) ->
    try
      mouseInput = new user32.MouseInput()
      mouseInput.type = 0
      mouseInput.dx = 0
      mouseInput.dy = 0
      mouseInput.mouseData = 0
      mouseInput.dwFlags =0x0004
      mouseInput.time = 0
      mouseInput.dwExtraInfo = 0
      user32.SendInput 1, mouseInput.ref(), 28
      next null, {}
    catch ex
      console.log "ex=#{ex}"
      next null, ex

  leftClick: (options, next) ->
    try
      mouseInput = new user32.MouseInput()
      mouseInput.type = 0
      mouseInput.dx = 0
      mouseInput.dy = 0
      mouseInput.mouseData = 0
      mouseInput.dwFlags =0x0002
      mouseInput.time = 0
      mouseInput.dwExtraInfo = 0
      user32.SendInput 1, mouseInput.ref(), 28

      mouseInput.dwFlags =0x0004
      user32.SendInput 1, mouseInput.ref(), 28
      next null, {}
    catch ex
      console.log "ex=#{ex}"
      next null, ex

privateServer = new PrivateServer
privateServer.addService "RemoteMouseService", new RemoteMouseService()
privateServer.start()

class MyDevice extends Device
  constructor: ->
    super('RemoteControl', {
      version: 1,
#      uuid: 'd2af1bd6-09d6-4669-8fc4-c04ccc4ffd8b',
      uuid: '63af7043-7b8d-45e5-9702-2ed9b3fef45b',
      services: {
        "RemoteControl": new RemoteControlService()
      }
    })

class RemoteControlService extends Service
  constructor:  ->
    super('RemoteControl', {version: 1})
  serviceDescription: "#{__dirname}/RemoteControl.xml"

  GetPrivateService: (req, options, next) ->
    console.log "RemoteControlService"
    console.log req.socket.address
    next null, { Address: req.socket.address().address, Port: privateServer.port}


ssdpServer = new upnp.Upnp(new MyDevice());
ssdpServer.on "error", (err) ->
  console.log err
ssdpServer.start();
