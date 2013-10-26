/**
 * Created by moon.wa on 10/19/13.
 */

Function.prototype.property = function(prop, descriptor) {
    return Object.defineProperty(this.prototype, prop, descriptor);
};
//var ffi = require ('ffi');
//var ref = require ('ref');
//var struct = require ('ref-struct');
//
//var MouseInput = struct ([
//['int', 'type' ],
//['int', 'dx' ],
//['int', 'dy'],
//['int', 'mouseData'],
//[ 'int', 'dwFlags'],
//['int', 'time'],
//['int', 'dwExtraInfo']
//]);
//var MouseInputPtr = ref.refType(MouseInput);
//var mouseInput = new MouseInput();
//mouseInput.type = 0;
//mouseInput.dx = 0;
//mouseInput.dy = 0;
//mouseInput.mouseData = 0;
//mouseInput.dwFlags = 2;
//mouseInput.time = 0;
//mouseInput.dwExtraInfo = 0;
//console.log (mouseInput)
//var user32 = ffi.Library ('user32',
//    { 'SendInput': [ 'int', [ 'int', MouseInputPtr , 'int' ] ] });
//setTimeout(function(){
//    var r = user32.SendInput (1, mouseInput.ref(), 28);
//    console.log (r);
//}, 100)
require ("coffee-script");
require ("./run");