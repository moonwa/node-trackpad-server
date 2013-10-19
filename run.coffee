ssdp = require './lib/ssdp'
Device = require './lib/device'
Service = require './lib/service'

class MyDevice extends Device
  constructor: ->
    super('rc-control', 1)
  createServices: ->
    {
      "service1": new MyService1()
    }
  serviceDescription: "#{__dirname}/MyDevice.xml"

class MyService1 extends Service
  constructor: ->
    super('trackpad', 1)


ssdpServer = new ssdp(new MyDevice(), "192.168.10.102");
ssdpServer.on "ready", ->