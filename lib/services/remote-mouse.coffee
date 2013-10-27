user32 = require "../user32"
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

  scroll: ( options, next) ->
    try
      console.log "scroll invoked x = #{options.offsetX}, y = #{options.offsetY}"
      mouseInput = new user32.MouseInput()
      mouseInput.type = 0
      mouseInput.dx = 0
      mouseInput.dy = 0
      mouseInput.mouseData = options.offsetY
      mouseInput.dwFlags =0x0800
      mouseInput.time = 0
      mouseInput.dwExtraInfo = 0
      user32.SendInput 1, mouseInput.ref(), 28

      next null, {}
    catch ex
      next null, ex

module.exports = RemoteMouseService