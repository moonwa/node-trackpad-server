upnp = require './lib/upnp'
Device = require './lib/device'
Service = require './lib/service'

class MyDevice extends Device
  constructor: ->
    super('MediaServer1', {
      version: 1,
#      uuid: 'd2af1bd6-09d6-4669-8fc4-c04ccc4ffd8b',
      uuid: '63af7043-7b8d-45e5-9702-2ed9b3fef45b',
      services: {
        "ContentDirectory": new MyService1(),
        "X_MS_MediaReceiverRegistrar": new MyService2()
      }
    })

class MyService1 extends Service
  constructor:  ->
    super('ContentDirectory', {version: 1})
  serviceDescription: "#{__dirname}/MyService.xml"

class MyService2 extends Service
  constructor:  ->
    super('X_MS_MediaReceiverRegistrar', {version: 1})
  serviceDescription: "#{__dirname}/MyService.xml"


ssdpServer = new upnp.Upnp(new MyDevice(), {address: "192.168.10.100"});
ssdpServer.on "error", (err) ->
  console.log err
ssdpServer.start();
