upnp = require './lib/upnp'
Device = require './lib/device'
Service = require './lib/service'

class MyDevice extends Device
  constructor: ->
    super('TestServer', {
      version: 1,
      uuid: 'd2af1bd6-09d6-4669-8fc4-c04ccc4ffd8b',
      services: {
        "service1": new MyService1()
      }
    })

class MyService1 extends Service
  constructor:  ->
    super('trackpad', {version: 1})
  serviceDescription: "#{__dirname}/MyService.xml"


ssdpServer = new upnp.Upnp(new MyDevice(), {address: "192.168.10.103"});
ssdpServer.on "error", (err) ->
  console.log err
ssdpServer.start();
