/**
 * Created by moon.wa on 10/19/13.
 */

require ("coffee-script");
ssdp = require ('./lib/ssdp')

var device = {
    address: "192.168.10.102",
    getUpnpType: function(){
        return [ 'urn',
            'schemas-upnp-org',
            'device',
            'rc-control',
            1
        ].join( ':');
    },
    name: "rc-control",
    services:[
        {
            name:'trackpad',
            getUpnpType: function(){
                return [ 'urn',
                    'schemas-upnp-org',
                    'service',
                    'trackpad',
                    1
                ].join( ':');
            }
        }
    ]
};
var ssdpServer = new ssdp(device);
ssdpServer.on("ready", function(){
    ssdpServer.announce( device)
})