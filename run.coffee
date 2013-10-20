upnp = require './lib/upnp'
Device = require './lib/device'
Service = require './lib/service'

class MyDevice extends Device
  constructor: ->
    super('Test Server', {
      version: 1,
      services: {
        "service1": new MyService1()
      }
    })

class MyService1 extends Service
  constructor:  ->
    super('trackpad', {version: 1})
  serviceDescription: "#{__dirname}/MyService.xml"


ssdpServer = new upnp.Upnp(new MyDevice(), {address: "192.168.10.102"});
ssdpServer.on "error", (err) ->
  console.log err
ssdpServer.start();
