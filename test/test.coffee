require "coffee-script"
should = require("should")
common = require "../server/common.coffee"
describe "Test single folder Sync",()->
    it "Folder Name Should Match",(done)->
        serverFolder = {name:"a"}
        clientFolder = {name:"b"}
        try
            common.syncFolder(clientFolder,[],serverFolder,[])
        catch e
            if e.message is "Folder Name Not Match" 
                done()
                return
            else
                done(e)
                return
        done new Error "Fail To Check Match"        
    it "Server Folder Empty/First Client Sync",(done)->
        serverFolder = {name:"a",todos:[]}
        serverHistory = []
        clientFolder = {name:"a",todos:[{name:"todoA",id:"12345",timestamp:0}]}
        clientHistory = []
        result = common.syncFolder clientFolder,clientHistory,serverFolder,serverHistory
        result.todos.length.should.equal(1)
        result.todos[0].timestamp.should.equal(0)
        result.todos[0].name.should.equal("todoA")
        result.todos[0].id.should.equal("12345")
        done()
    it "Broken Todo With No Id or Time Stamp Should Raise Error",(done)->
        
        serverFolder = {name:"a",todos:[]}
        serverHistory = []
        clientFolderNoId = {name:"a",todos:[{name:"todoA",timestamp:0}]}
        clientFolderNoTimestamp = {name:"a",todos:[{name:"todoA",id:"123"}]}
        clientHistory = []
        pass =false
        try
            common.syncFolder clientFolderNoId,clientHistory,serverFolder,serverHistory
        catch e
            if e.message is "Todo Has No Id"
                pass = true
            else
                done e
        if not pass
            done new Error "Not Throw With No Id Todo"
        pass =false
        try
            common.syncFolder clientFolderNoTimestamp,clientHistory,serverFolder,serverHistory
        catch e
            if e.message is "Todo Has No Timestamp"
                pass = true
            else
                done e
        if not pass
            done new Error "Not Throw With No Id Timestamp"
        done()
    it "Client Empty/First Client Sync",(done)->
        serverFolder = {name:"a",todos:[{name:"todoA",id:"12345",timestamp:0}]}
        serverHistory = []
        clientFolder = {name:"a",todos:[]}
        clientHistory = []
        result = common.syncFolder clientFolder,clientHistory,serverFolder,serverHistory
        result.todos.length.should.equal(1)
        result.todos[0].timestamp.should.equal(0)
        result.todos[0].name.should.equal("todoA")
        result.todos[0].id.should.equal("12345")
        done()
    it "Server Delete Client Do So",(done)->
        serverFolder = {name:"a",todos:[]}
        serverHistory = [{action:"deleteTodo",todoId:"12345"}]
        clientFolder = {name:"a",todos:[{name:"todoA",id:"12345",timestamp:0}]}
        clientHistory = []
        result = common.syncFolder clientFolder,clientHistory,serverFolder,serverHistory
        result.todos.length.should.equal(0)
        clientHistory.length.should.equal(1)
        clientHistory[0].todoId.should.equal("12345")
        done()
    it "Client Delete Server Do So",(done)->
        serverFolder = {name:"a",todos:[{name:"todoA",id:"12345",timestamp:0}]}
        serverHistory = []
        clientFolder = {name:"a",todos:[]}
        clientHistory = [{action:"deleteTodo",todoId:"12345"}]
        result = common.syncFolder clientFolder,clientHistory,serverFolder,serverHistory
        result.todos.length.should.equal(0)
        serverHistory.length.should.equal(1)
        serverHistory[0].todoId.should.equal("12345")
        done()
    
    it "Server Folder Empty/First Client Sync With Broken Data Should Fail",(done)->
        serverFolder = {name:"a",todos:[]}
        serverHistory = []
        clientFolder = {name:"a",todos:[{name:"todoA"}]}
        clientHistory = []
        try 
            result = common.syncFolders {folders:[clientFolder],history:clientHistory},{folders:[],history:serverHistory}
        catch e
            if e.message is "Broken Todo Message"
                done()
                return
            console.error e
            done(e)
    it "Complicated Example",(done)->
        serverFolder = {name:"a",todos:[{name:"todo1",id:"1",timestamp:0},{name:"todo2",id:"2",timestamp:0},{name:"todo4",id:"4",timestamp:0}]}
        serverHistory = []
        clientFolder = {name:"a",todos:[{name:"todo2changed",id:"2",timestamp:1},{name:"todo3",id:"3",timestamp:0}]}
        clientHistory = [{action:"deleteTodo",todoId:"1"}]
        result = common.syncFolder clientFolder,clientHistory,serverFolder,serverHistory
        serverHistory.length.should.equal(1)
        serverHistory[0].todoId.should.equal("1")
        result.todos.length.should.equal(3)
        result.todos[0].id.should.equal("2") 
        result.todos[1].id.should.equal("3") 
        result.todos[2].id.should.equal("4")
        done()
describe " Test All Folders Sync",()->
    it "First Time Client Sync/Server Empty",(done)-> 
        client = {
            ,lastUpdate:10
            ,folders:[
                {name:"hello",todos:[]}
            ]
            ,history:[]
        }
        server = {
            ,history:[]
            ,folders:[]
            }
        result = common.sync client,server
        result.should.be.true
        client.folders.length.should.equal(1)
        client.folders[0].name.should.equal("hello")
        client.history.length.should.equal(0)
        server.folders.length.should.equal(1)
        server.folders[0].name.should.equal("hello")
        server.history.length.should.equal(0)
        done()    
    it "Another Client Delete Folder With Log And Sync To Server",(done)-> 
        client = {
            ,lastUpdate:20
            ,folders:[
                {name:"folderA",todos:[],timestamp:0}
            ]
            ,history:[]
        }
        server = {
            ,history:[{action:"deleteFolder",folderName:"folderA",timestamp:20}]
            ,folders:[]
            }
        result = common.sync client,server
        result.should.be.true
        client.folders.length.should.equal(0)
        client.history.length.should.equal(1)
        server.folders.length.should.equal(0)
        server.history.length.should.equal(1)
        server.history[0].folderName.should.equal("folderA")
        done()
    it "Another Client Delete Folder With Log But Recreate By Client",(done)-> 
        client = {
            ,lastUpdate:20
            ,folders:[
                {name:"folderA",todos:[],timestamp:200}
            ]
            ,history:[]
        }
        server = {
            ,history:[{action:"deleteFolder",folderName:"folderA",timestamp:20}]
            ,folders:[]
            }
        result = common.sync client,server
        result.should.be.true
        client.folders.length.should.equal(1)
        client.history.length.should.equal(0)
        server.folders.length.should.equal(1)
        server.history.length.should.equal(0)
        done()

    it "Complicated Example Client Priority",(done)-> 
        client = {
            ,lastUpdate:20
            ,lastSync:0
            ,folders:[
                {name:"folderA",todos:[],timestamp:200} # recreate
                ,{name:"folderB",todos:[],timestamp:0}
                ,{name:"folderC",todos:[],timestamp:0}
                ,{name:"folderE",todos:[name:"E:todoA",timestamp:0,id:"003"]}
            ]
            ,history:[{action:"deleteFolder",folderName:"folderD",timestamp:20}]
        }
        server = {
            lastUpdate:0
            ,lastSync:0
            ,history:[{action:"deleteFolder",folderName:"folderA",timestamp:20}]
            ,folders:[
                {name:"folderF",todos:[{name:"F:todoA",id:"004",timestamp:0}],timestamp:0}
                ,{name:"folderB",todos:[{name:"B:todoA",id:"123",timestamp:0}],timestamp:0}
                ,{name:"folderD",todos:[],timestamp:0}
                ]
            }
        result = common.sync client,server
        result.should.be.true
        client.folders.length.should.equal(5)
        client.history.length.should.equal(1)
        server.folders.length.should.equal(5)
        server.history.length.should.equal(1)
        server.folders.should.equal(client.folders)
        server.folders[0].name.should.equal("folderA")
        server.folders[1].name.should.equal("folderB")
        server.folders[2].name.should.equal("folderC")
        server.folders[3].name.should.equal("folderE")
        server.folders[4].name.should.equal("folderF")

        server.folders[3].todos.length.should.equal(1)
        server.folders[4].todos.length.should.equal(1)

        done()
    it "Complicated Example Server Priority",(done)-> 
        client = {
            ,lastUpdate:0
            ,lastSync:0
            ,folders:[
                {name:"folderA",todos:[],timestamp:200} # recreate
                ,{name:"folderB",todos:[],timestamp:0}
                ,{name:"folderC",todos:[],timestamp:0}
                ,{name:"folderE",todos:[name:"E:todoA",timestamp:0,id:"003"]}
            ]
            ,history:[{action:"deleteFolder",folderName:"folderD",timestamp:20}]
        }
        server = {
            lastUpdate:15
            ,lastSync:20
            ,history:[{action:"deleteFolder",folderName:"folderA",timestamp:20}]
            ,folders:[
                {name:"folderF",todos:[{name:"F:todoA",id:"004",timestamp:0}],timestamp:0}
                ,{name:"folderB",todos:[{name:"B:todoA",id:"123",timestamp:0}],timestamp:0}
                ,{name:"folderD",todos:[],timestamp:0}
                ]
            }
        result = common.sync client,server
        result.should.be.true
        client.folders.length.should.equal(5)
        client.history.length.should.equal(1)
        server.folders.length.should.equal(5)
        server.history.length.should.equal(1)
        server.folders.should.equal(client.folders)
        server.folders[0].name.should.equal("folderF")
        server.folders[1].name.should.equal("folderB")
        server.folders[2].name.should.equal("folderA")
        server.folders[3].name.should.equal("folderC")
        server.folders[4].name.should.equal("folderE") 
        server.folders[0].todos.length.should.equal(1)
        server.folders[4].todos.length.should.equal(1)
        
        done()

