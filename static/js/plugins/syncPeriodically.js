// Generated by CoffeeScript 1.6.2
(function() {
  var SyncPeriodically;

  SyncPeriodically = (function() {
    function SyncPeriodically() {
      this.timer = null;
      this.syncInterval = 1000 * 60 * 10;
    }

    SyncPeriodically.prototype.load = function() {
      console.log("Plugin Sync Periodically Loaded");
      return this.timer = setInterval((function() {
        return App.yatodo.actionBar.onClickSyncButton();
      }), this.syncInterval);
    };

    SyncPeriodically.prototype.unload = function() {
      return clearInterval(this.timer);
    };

    return SyncPeriodically;

  })();

  Plugins.push(new SyncPeriodically());

}).call(this);

/*
//@ sourceMappingURL=syncPeriodically.map
*/
