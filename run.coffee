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

ssdpServer = new upnp.Upnp(new MyDevice(), {address: "192.168.10.102"});
ssdpServer.on "error", (err) ->
  console.log err
ssdpServer.start();
