// Generated by CoffeeScript 1.6.2
(function() {
  var Collections, Database, ObjectID, async, collectionNames, dbConnector, dbServer, mongodb, settings;

  mongodb = require("mongodb");

  async = require("async");

  ObjectID = (require("mongodb")).ObjectID;

  settings = (require("./settings")).settings;

  dbServer = mongodb.Server(settings.database.host, settings.database.port, settings.database.option);

  collectionNames = ["user"];

  dbConnector = new mongodb.Db(settings.database.name, dbServer, {
    safe: false
  });

  exports.DatabaseReady = false;

  Collections = {};

  exports.Collections = Collections;

  Database = null;

  dbConnector.open(function(err, db) {
    if (err || !db) {
      console.error("fail to connect to mongodb");
      console.error(err);
      process.exit(1);
    }
    dbConnector.db = db;
    Database = null;
    return async.map(collectionNames, (function(collectionName, callback) {
      dbConnector.db.collection(collectionName, function(err, col) {
        if (err) {
          return callback(err);
        } else {
          return callback(null, col);
        }
      });
      return true;
    }), function(err, results) {
      var index, name, _i, _len;

      if (err) {
        console.error("fail to prefetch Collections");
        process.exit(1);
        return;
      }
      for (index = _i = 0, _len = collectionNames.length; _i < _len; index = ++_i) {
        name = collectionNames[index];
        Collections[name] = results[index];
      }
      exports.DatabaseReady = true;
      if (exports.onready) {
        return exports.onready();
      }
    });
  });

}).call(this);

/*
//@ sourceMappingURL=db.map
*/
