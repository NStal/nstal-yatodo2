require "coffee-script"
express = require "express"
async = require "async"
mongodb = require "mongodb"
crypto = require "crypto"
path = require "path"
db = require "./db.coffee"
Collections = db.Collections
MongoStore = require("connect-mongo")(express)
Error  = (require "./error").Error
settings = (require "./settings").settings
ObjectID = (require "mongodb").ObjectID
childProcess = require "child_process"
simulateDelay = process.argv[2] is "delay"
delayTime = 500

common = require "./common"

if simulateDelay
    console.log "use delay mode of %d ms",delayTime
#init database
app = express()
app.enable "trust proxy"
app.use express.bodyParser()
app.use express.cookieParser()
app.use express.session({
    secret:settings.sessionSecret
    key:"mikupantsu"
    store:new MongoStore({db:settings.database.name})
    })
# db check ready
app.use (req,res,next)->
    if not db.DatabaseReady
        res.status 503
        res.json {"error":"Server Not Ready"}
        return
    next()
# descriptor for json response
app.use (req,res,next)->
    res.json = (obj)->
        if not res.responseContentType
            res.setHeader("Content-Type","text/json")
        else
            res.setHeader("Content-Type",res.responseContentType)
        if simulateDelay
            setTimeout (()-> 
                res.end(JSON.stringify(obj))
            ),delayTime
            return
        res.end(JSON.stringify(obj))
    res.success = (obj)->
        res.json {state:true,data:obj}
    res.jsonError = (description,errorCode,subCode)->
        @json({
            state:false
            error:description
            errorCode:errorCode #Abstract general error code
            subCode:subCode #detail error code used for custom Error
            })
    res.serverError = ()->
        res.jsonError "Server Error",Error.ServerError 
    next()

app.post "/api/signup",(req,res)->
    username = req.param("username",null) 
    password = req.param("password","")
    email = req.param("email",undefined)
    console.log username,password,email
    date = new Date()
    # username at least 3 regular charactor
    if not username
        res.jsonError "Invalid Username",Error.InvalidParameter
        return
    if not /^[a-z0-9_]{3,64}$/i.test username
        res.jsonError "Invalid Username",Error.InvalidParameter
        return
    # hash with salt
    hash = crypto.createHash("sha1").update(password+date.getTime()).digest("hex");
    Collections.user.find {username:username},(err,cursor)->
        if err or !cursor
            res.jsonError("Server Error")
            return
        cursor.toArray (err,results)->
            if err
                res.jsonError("Server Error")
                return
            if results.length>0
                res.jsonError("Username Exists",Error.AlreadyExists)
                return 
            Collections.user.insert {username:username,password:hash,date:date,archiveCount:0} 
            
            req.session.username = username
            req.session.trust = true
            req.session.maxAge = settings.defaultExpire
            res.success()
            return

app.post "/api/signin",(req,res)->
    username = req.param("username",null)
    password = req.param("password","")
    if not username
        res.jsonError "Invalid Parameter",Error.InvalidParameter
        return
    Collections.user.findOne {username:username},(err,doc)->
        if err
            res.serverError()
            return
        if not doc 
            res.jsonError "Authorization Failed",Error.AuthorizationFailed
            return
        #dateString is memomeme old version support
        salt = doc.dateString or doc.date.getTime()
        if (crypto.createHash("sha1").update(password+salt).digest("hex").toString() isnt doc.password)
            res.jsonError "Authorization Failed",Error.AuthorizationFailed
            return
        req.session.username = username
        req.session.trust = true
        req.session.maxAge = settings.defaultExpire
        res.success()
        return 
        



# auth for all the API below
app.post "/api/:apiname",(req,res,next)->
    if req.session.trust and req.session.username
        next()
        return
    res.jsonError("Authorization Failed",Error.AuthorizationFailed)
    return
app.post "/api/signout",(req,res)->
    if req.session.username and req.session.trust
        req.session.destroy()
        res.json({state:true})
    else
        res.serverError()
app.post "/api/getProfile",(req,res,next)->
    if not req.session.username
        console.error "Should'nt reach here"
        console.error "Request Information",req
        console.trace()
        return 
    Collections.user.findOne {username:req.session.username},(err,user)->
        if err
            console.error "Server Error",err
            res.serverError()
            return
        if not user 
            console.error "Should'nt reach here"
            console.error "Request Information"
            console.trace()
            return
        profile = {
            username:user.username
            email:user.email
            archiveCount:user.archiveCount
            }
        res.success profile
app.post "/api/updateEmail",(req,res,next)->
    username = req.session.username
    email = req.param("email","")
    # empty email is OK
    if not /[a-z0-9.]+@[a-z0-9.]+/.test(email) and email.length > 0
        res.jsonError("Invalid Parameter",Error.InvalidParameter)
        return
    Collections.user.findOne {username:username},(err,user)->
        if err
            console.error("Server Error",err)
            res.serverError()
            return
        if not user
            console.error("User Not Found","username%s",username)
            console.error("Should'nt reach here")
            return
        user.email = email
        Collections.user.update {username:username},{$set:{
            email:email
            }}
        res.success()


app.post "/api/updatePassword",(req,res,next)->
    username = req.session.username
    password = req.param("password","")
    newPassword = req.param("newPassword",null)
    if not newPassword
        res.jsonError("Invalid Parameter",Error.InvalidParameter)
        return
    if not username
        console.error "Should'nt reach here"
        res.serverError()
        return
    Collections.user.findOne {username:username},(err,user)->
        if err
            console.error "Server Error",err 
            res.serverError()
            return
        if not user
            console.error "User Not Found",username
            res.serverError()
            return
        salt = user.date.getTime()
        hash = crypto.createHash("sha1").update(password+salt).digest("hex");
        if hash isnt user.password
            res.jsonError "Authorization Failed",Error.AuthorizationFailed
            return
        user.password = crypto.createHash("sha1").update(newPassword+user.date.getTime()).digest("hex");
        delete user.dateString
        Collections.user.update {username:username},user
        req.session.destroy()
        res.success()

app.post "/api/sync",(req,res,next)->
    #doc refer to /case.org
    if not req.session.username
        console.error "Should'nt reach here"
        console.error "Request Information",req
        console.trace()
        return
    try
        data = JSON.parse(req.param("data"))
        lastSync = parseInt(req.param("lastSync",0)) or 0
        lastUpdate = parseInt(req.param("lastUpdate",0)) or 0
    catch e
        console.error "invalid data",req.param("data")
        res.jsonError "Invalid Parameter",Error.InvalidParameter
    client = {
        folders:data.folders or []
        ,history:data.history or []
        ,lastSync:lastSync
        ,lastUpdate:lastUpdate
    }
    Collections.user.findOne {username:req.session.username},(err,user)->
        if err or not user 
            console.error "Server Error",err
            res.serverError()
            return
        todo = user.todo or {}
        server = {
            folders:todo.folders or []
            ,history:todo.history or []
            ,lastSync:todo.lastSync or 0
            ,lastUpdate:todo.lastUpdate or 0
            
            }
        console.log client,server
        client.folders = client.folders.filter (item)->
            return item
        server.folders = server.folders.filter (item)->
            return item
        try
            common.sync client,server
        catch e
            console.error e
            res.jsonError "Invalid Parameter",Error.InvalidParameter
            return
        res.success(client)
        Collections.user.update {username:user.username},{$set:{todo:server}}        
app.post "/api/getProfile",(req,res,next)->
    if not req.session.username
        console.error "Should'nt reach here"
        console.error "Request Information",req
        console.trace()
        return 
    Collections.user.findOne {username:req.session.username},(err,user)->
        if err
            console.error "Server Error",err
            res.jsonError "Server Error",Error.ServerError
            return
        if not user 
            console.error "Should'nt reach here"
            console.error "Request Information"
            console.trace()
            return
        profile = {
            username:user.username
            email:user.email
            archiveCount:user.archiveCount
            }
        res.success profile
#handle final result
app.all "/api/:apiname",(req,res,next)->
    res.status 404
    res.jsonError("Api Not Found",Error.NotFound)

app.listen 14086
