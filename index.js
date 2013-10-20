/**
 * Created by moon.wa on 10/19/13.
 */

Function.prototype.property = function(prop, descriptor) {
    return Object.defineProperty(this.prototype, prop, descriptor);
};
require ("coffee-script");
require ("./run");