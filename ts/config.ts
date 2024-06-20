declare var requirejs:any, require:any;

requirejs.config({
    paths: {},
    urlArgs: function(id:any, url:any) {
        var rando = (window as any)["getRandomVersionNumber"]();
        var args = '?v=' + rando;
        return args;
    }
});

require(["ux"]);