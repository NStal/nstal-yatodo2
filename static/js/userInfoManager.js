// Generated by CoffeeScript 1.6.2
(function() {
  var SigninBox, SignupBox, UserInfoManager,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  UserInfoManager = (function(_super) {
    __extends(UserInfoManager, _super);

    function UserInfoManager() {
      UserInfoManager.__super__.constructor.call(this);
      this.isSignedIn = false;
    }

    UserInfoManager.prototype.signin = function(username, password) {
      var req,
        _this = this;

      console.assert(username);
      console.assert(password);
      return req = API.signin(username, password).success(function(data) {
        _this.isSignedIn = true;
        _this.username = username;
        return _this.emit("signin");
      }).fail(function(err, detail) {
        console.error(err, detail);
        _this.emit("failToSignin");
        return _this.isSignedIn = false;
      });
    };

    UserInfoManager.prototype.signout = function() {
      var req;

      if (confirm("确认要登出吗?")) {
        if (confirm("清楚本地数据吗?(如果要用另一账户登陆请务必选择\"是\")")) {
          App.dataManager.clearUserData();
        }
        console.log("~~~");
        req = API.signout();
        req.success(function() {
          App.yatodo.hint(Language.successfullySignout);
          return window.location = window.location;
        });
        return req.fail(function() {
          return App.yatodo.warn(Language.failToSignout);
        });
      }
    };

    return UserInfoManager;

  })(Leaf.EventEmitter);

  SignupBox = (function(_super) {
    __extends(SignupBox, _super);

    function SignupBox() {
      SignupBox.__super__.constructor.call(this, App.templates["signup-box"]);
      this.km = new Leaf.KeyEventManager();
      this.km.attachTo(window);
    }

    SignupBox.prototype.show = function() {
      SignupBox.__super__.show.call(this);
      return Leaf.KeyEventManager.disable();
    };

    SignupBox.prototype.hide = function() {
      SignupBox.__super__.hide.call(this);
      Leaf.KeyEventManager.enable();
      return this.km.unmaster();
    };

    SignupBox.prototype.onClickToSigninBox = function() {
      this.hide();
      return App.yatodo.signinBox.show();
    };

    SignupBox.prototype.onClickSignupButton = function() {
      var password, req, username;

      if (this.UI.password.value !== this.UI.passwordConfirm.value) {
        App.yatodo.warn(Language.passwordNotMatch);
        return;
      }
      if (!this.UI.username.value) {
        App.yatodo.warn(Language.pleaseEnterUsername);
        return;
      }
      if (!this.UI.password.value) {
        App.yatodo.warn(Language.pleaseEnterPassword);
        return;
      }
      username = this.UI.username.value;
      password = this.UI.password.value;
      req = API.signup(username, password);
      return req.success(function(data) {
        return App.userInfoManager.signin(username, password);
      }).fail(function(err, detail) {
        console.error(err, detail);
        return App.yatodo.warn(Language.serverError);
      });
    };

    return SignupBox;

  })(FadeBox);

  SigninBox = (function(_super) {
    __extends(SigninBox, _super);

    function SigninBox() {
      SigninBox.__super__.constructor.call(this, App.templates["signin-box"]);
      this.km = new Leaf.KeyEventManager();
      this.km.attachTo(window);
    }

    SigninBox.prototype.show = function() {
      SigninBox.__super__.show.call(this);
      return Leaf.KeyEventManager.disable();
    };

    SigninBox.prototype.hide = function() {
      SigninBox.__super__.hide.call(this);
      return Leaf.KeyEventManager.enable();
    };

    SigninBox.prototype.onClickClose = function() {
      return this.hide();
    };

    SigninBox.prototype.onClickToSignupBox = function() {
      this.hide();
      return App.yatodo.signupBox.show();
    };

    SigninBox.prototype.onClickSigninButton = function() {
      var password, username;

      if (!this.UI.username.value) {
        App.yatodo.warn(Language.pleaseEnterUsername);
        return;
      }
      if (!this.UI.password.value) {
        App.yatodo.warn(Language.pleaseEnterPassword);
        return;
      }
      username = this.UI.username.value;
      password = this.UI.password.value;
      return App.userInfoManager.signin(username, password);
    };

    return SigninBox;

  })(FadeBox);

  window.SigninBox = SigninBox;

  window.SignupBox = SignupBox;

  window.UserInfoManager = UserInfoManager;

}).call(this);

/*
//@ sourceMappingURL=userInfoManager.map
*/
