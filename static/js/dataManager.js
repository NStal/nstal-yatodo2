// Generated by CoffeeScript 1.6.2
(function() {
  var DataManager,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  DataManager = (function(_super) {
    __extends(DataManager, _super);

    function DataManager() {
      var _this = this;

      DataManager.__super__.constructor.call(this);
      this.lastSync = 0;
      this.lastUpdate = 0;
      this.defaultFolderName = "daily";
      this.restoreFromLocalStorage();
      this.remoteSync();
      App.userInfoManager.on("signin", function() {
        if (_this.username !== null && App.userInfoManager.username !== _this.username) {
          _this.clearUserData();
        }
        localStorage.setItem("username", App.userInfoManager.username);
        _this.restoreFromLocalStorage();
        return _this.remoteSync();
      });
    }

    DataManager.prototype.deleteFolder = function(_folder) {
      var folder, index, _i, _len, _ref;

      _ref = this.data.folders;
      for (index = _i = 0, _len = _ref.length; _i < _len; index = ++_i) {
        folder = _ref[index];
        if (folder.name === _folder.name) {
          console.assert(folder.timestamp === _folder.timestamp);
          this.data.folders.splice(index, 1);
          this.addHistory({
            action: "deleteFolder",
            folderName: folder.name
          });
          return true;
        }
      }
      return false;
    };

    DataManager.prototype.createFolder = function(_folder) {
      var folder, _i, _len, _ref;

      if (!_folder.name) {
        App.yatodo.hint(Language.folderShouldHasAName);
        return null;
      }
      _ref = this.data.folders;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        folder = _ref[_i];
        if (folder.name === _folder.name) {
          App.yatodo.hint(Language.folderWithSameNameExists);
          return null;
        }
      }
      this.data.folders.push(_folder);
      this.lastUpdate = Date.now();
      this.saveToLocalStorage();
      return _folder;
    };

    DataManager.prototype.setFolderData = function(newFolder) {
      var folder, _i, _len, _ref;

      console.assert(newFolder);
      _ref = this.data.folders;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        folder = _ref[_i];
        if (folder.name === newFolder.name) {
          console.log(folder, newFolder);
          console.assert(folder.timestamp === newFolder.timestamp);
          folder.todos = newFolder.todos;
          this.saveToLocalStorage();
          return folder;
        }
      }
      return null;
    };

    DataManager.prototype.addHistory = function(log) {
      log.timestamp = Date.now();
      this.data.history.push(log);
      return this.saveToLocalStorage();
    };

    DataManager.prototype.getFolder = function(_folder) {
      var folder, _i, _len, _ref;

      _ref = this.data.folders;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        folder = _ref[_i];
        if (folder.name === _folder.name) {
          return folder;
        }
      }
      return null;
    };

    DataManager.prototype.set = function(data) {
      this.data = this.check(data);
      console.log("set", data);
      this.lastUpdate = Date.now();
      return this.saveToLocalStorage();
    };

    DataManager.prototype.check = function(data) {
      console.assert(data.history instanceof Array);
      console.assert(data.folders instanceof Array);
      return data;
    };

    DataManager.prototype.restoreFromLocalStorage = function() {
      var data, init;

      if (!localStorage) {
        return;
      }
      init = localStorage.getItem("init");
      this.user = localStorage.getItem("username");
      if (!init || init === "yes") {
        this.isFirstTime = true;
      } else {
        this.isFirstTime = false;
      }
      data = localStorage.getItem("data");
      if (data) {
        this.data = JSON.parse(data);
        if (this.data.folders instanceof Array) {
          this.data.folders = this.data.folders.filter(function(value) {
            return value;
          });
        }
        if (!this.data.folders || this.data.folders.length === 0) {
          this.data.folders = [this.createDefaultFolder()];
        }
        if (!this.data.history) {
          this.data.history = [];
        }
      } else {
        this.data = {
          folders: [this.createDefaultFolder()],
          history: []
        };
      }
      this.lastSync = parseInt(localStorage.getItem("lastSync")) || 0;
      return this.lastUpdate = parseInt(localStorage.getItem("lastUpdate")) || 0;
    };

    DataManager.prototype.createDefaultFolder = function() {
      return {
        name: this.defaultFolderName,
        todos: [],
        timestamp: 0
      };
    };

    DataManager.prototype.clearUserData = function() {
      localStorage.removeItem("lastUpdate");
      localStorage.removeItem("lastSync");
      localStorage.removeItem("data");
      return localStorage.setItem("init", "yes");
    };

    DataManager.prototype.saveToLocalStorage = function() {
      localStorage.setItem("lastUpdate", this.lastUpdate.toString());
      localStorage.setItem("lastSync", this.lastSync.toString());
      return localStorage.setItem("data", JSON.stringify(this.data));
    };

    DataManager.prototype.remoteSync = function() {
      var call, sendData,
        _this = this;

      this.emit("syncStart");
      sendData = {
        folders: this.data.folders,
        history: this.data.history || []
      };
      if (this.isFirstTime && this.data.folders.length === 1 && this.data.folders[0].name === this.defaultFolderName && this.data.folders[0].todos.length === 0) {
        sendData.folders = [];
      }
      console.log(sendData.folders[0]);
      call = API.sync(JSON.stringify(sendData), this.lastSync, this.lastUpdate);
      return call.success(function(data) {
        _this.data = data;
        _this.lastSync = data.lastSync;
        _this.lastUpdate = data.lastUpdate;
        if (_this.data.folders.length === 0) {
          _this.data.folders = [_this.createDefaultFolder()];
        }
        localStorage.setItem("init", "no");
        _this.saveToLocalStorage();
        App.yatodo.hint(Language.syncedSuccessfully);
        _this.emit("synced");
        return _this.emit("syncEnd");
      }).fail(function(err, detail) {
        console.error("fail to sync with server", err, detail);
        if (err === "Authorization Failed") {
          App.yatodo.suggestSignin();
          App.yatodo.hint(Language.youNeedToSigninToSync);
        } else {
          App.yatodo.warn("Net Work Error");
        }
        return _this.emit("syncEnd");
      });
    };

    return DataManager;

  })(Leaf.EventEmitter);

  window.DataManager = DataManager;

}).call(this);

/*
//@ sourceMappingURL=dataManager.map
*/