class UserInfoManager extends Leaf.EventEmitter
    constructor:()->
        super()
        @isSignedIn = false
    signin:(username,password)->
        console.assert username
        console.assert password
        req = API.signin(username,password)
            .success (data)=>
                @isSignedIn = true
                @username = username
                @emit "signin"
            .fail (err,detail)=>
                console.error err,detail
                @emit "failToSignin"
                @isSignedIn = false
    signout:()->
        if confirm("确认要登出吗?") 
            if confirm("清楚本地数据吗?(如果要用另一账户登陆请务必选择\"是\")") 
                App.dataManager.clearUserData()
            console.log "~~~"
            req = API.signout()
            req.success ()->
                App.yatodo.hint Language.successfullySignout
                window.location = window.location 
            req.fail ()->
                App.yatodo.warn Language.failToSignout
class SignupBox extends FadeBox
    constructor:()->
        super(App.templates["signup-box"])
        @km = new Leaf.KeyEventManager()
        @km.attachTo window
    show:()->
        super()
        @km.master()
    hide:()->
        super()
        @km.unmaster()

    onClickToSigninBox:()->
        @hide()
        App.yatodo.signinBox.show()
    onClickSignupButton:()->
        if @UI.password.value isnt @UI.passwordConfirm.value
            App.yatodo.warn Language.passwordNotMatch
            return
        if not @UI.username.value
            App.yatodo.warn Language.pleaseEnterUsername
            return
        if not @UI.password.value
            App.yatodo.warn Language.pleaseEnterPassword
            return
        username = @UI.username.value
        password = @UI.password.value
        req = API.signup username,password
        req.success (data)->
            App.userInfoManager.signin username,password
        .fail (err,detail)->
            console.error err,detail
            App.yatodo.warn Language.serverError

class SigninBox extends FadeBox
    constructor:()->
        super App.templates["signin-box"]
        @km = new Leaf.KeyEventManager()
        @km.attachTo window
    show:()->
        super()
        console.log "~~~"
        @km.master()
    hide:()->
        super()
        @km.unmaster()
    onClickClose:()->
        @hide()
    onClickToSignupBox:()->
        @hide()
        App.yatodo.signupBox.show()
    onClickSigninButton:()->
        if not @UI.username.value
            App.yatodo.warn Language.pleaseEnterUsername
            return
        if not @UI.password.value
            App.yatodo.warn Language.pleaseEnterPassword
            return
        username = @UI.username.value
        password = @UI.password.value
        App.userInfoManager.signin username,password
            
        
        
window.SigninBox = SigninBox
window.SignupBox = SignupBox
window.UserInfoManager = UserInfoManager