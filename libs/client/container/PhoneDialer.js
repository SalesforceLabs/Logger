
var PhoneDialer = function() {
    
}

// call this to register for push notifications
PhoneDialer.prototype.dial = function(phnum) {
    cordova.exec(null, null, "phonedialer", "dialPhone", [{"number":phnum}]);
};


cordova.addConstructor(function() {
    if(!window.plugins) {
        window.plugins = {};
    }
    window.plugins.phoneDialer = new PhoneDialer();
});