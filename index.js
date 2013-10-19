/**
 * Created by moon.wa on 10/19/13.
 */

require ("coffee-script");
ssdp = require ('./lib/ssdp')

console.log (ssdp)
var ssdpServer = new ssdp();
var device = {
    name: "rc-control",
    services:[
        {
            name:'trackpad'
        }
    ]
};
ssdpServer.on("ready", function(){
    ssdpServer.announce( device)
})