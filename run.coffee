upnp = require './lib/upnp'
Device = require './lib/device'
Service = require './lib/service'
PrivateServer = require './lib/private-server'
user32 = require './lib/user32'
kernel32 = require './lib/kernel32'
ffi = require 'ffi'
ref = require 'ref'

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

  GetPrivateService: (options, next) ->
    console.log "RemoteControlService"
    next null, {Address: "192.168.10.102", Port: 3001}

class RemoteMouseService 
  moveOffset: (options, next) ->
    try
      console.log "move invoked x = #{options.offsetX}, y = #{options.offsetY}"

      point = new user32.Point()
      user32.GetCursorPos point.ref()
      user32.SetCursorPos point.X + options.offsetX, point.Y + options.offsetY
      next null, {}
    catch ex
      next null, ex

  leftDown: (options, next) ->
    try
      console.log "left down invoked"
      console.log "left down invoked"
      console.log "left down invoked"
      console.log "left down invoked"

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
      console.log "LeftUp invoked"
      console.log "LeftUp invoked"
      console.log "LeftUp invoked"
      console.log "LeftUp invoked"

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
      console.log "LeftClick invoked"
      console.log "LeftClick invoked"
      console.log "LeftClick invoked"
      console.log "LeftClick invoked"

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

ssdpServer = new upnp.Upnp(new MyDevice(), {address: "192.168.10.102"});
ssdpServer.on "error", (err) ->
  console.log err
ssdpServer.start();
