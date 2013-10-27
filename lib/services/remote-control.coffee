Service = require "./service"
user32 = require "../user32"
class RemoteControlService extends Service
  constructor: (@privateServer) ->
    super('RemoteControl', {version: 1})
  serviceDescription: "#{__dirname}/RemoteControl.xml"

  GetPrivateService: (req, options, next) ->
    console.log "RemoteControlService"
    console.log req.socket.address
    next null, { Address: req.socket.address().address, Port: @privateServer.port}

  MoveOffset: (req, options, next) ->
    try
      console.log "move invoked x = #{options.offsetX}, y = #{options.offsetY}"

      point = new user32.Point()
      user32.GetCursorPos point.ref()
      user32.SetCursorPos point.X + parseInt(options.OffsetX[0]), point.Y  + parseInt(options.OffsetY[0])
      next null, {}
    catch ex
      next null, ex

  LeftDown: (req, options, next) ->
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
  LeftUp: (req, options, next) ->
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

  LeftClick: (req, options, next) ->
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

module.exports = RemoteControlService