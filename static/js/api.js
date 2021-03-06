// Generated by CoffeeScript 1.6.2
(function() {
  var factory;

  factory = new Leaf.ApiFactory();

  factory.path = "api/";

  factory.defaultMethod = "POST";

  factory.declare("signup", ["username:string", "password:string", "email:?"]);

  factory.declare("signin", ["username:string", "password:string"]);

  factory.declare("signout", []);

  factory.declare("sync", ["data:string", "lastSync:number?", "lastUpdate:number?"]);

  window.API = factory.build();

}).call(this);

/*
//@ sourceMappingURL=api.map
*/
