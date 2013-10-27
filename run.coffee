upnp = require './lib/upnp'
Device = require './lib/device'
PrivateServer = require './lib/private-server'
user32 = require './lib/user32'
kernel32 = require './lib/kernel32'
utils = require './lib/utils'

RemoteMouseService = require './lib/services/remote-mouse'
RemoteControlService = require './lib/services/remote-control'

privateServer = new PrivateServer 3001
privateServer.addService "RemoteMouseService", new RemoteMouseService()
privateServer.start()

class MyDevice extends Device
  constructor: ->
    super('RemoteControl', {
      version: 1,
#      uuid: 'd2af1bd6-09d6-4669-8fc4-c04ccc4ffd8b',
      uuid: '63af7043-7b8d-45e5-9702-2ed9b3fef45b',
      services: {
        "RemoteControl": new RemoteControlService(privateServer)
      }
    })
#aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
ssdpServer = new upnp.Upnp(new MyDevice(), 3000);
ssdpServer.on "error", (err) ->
  console.log err
ssdpServer.start();
