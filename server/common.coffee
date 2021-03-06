
todoProperties = ["name","done","description"]
todoPropertiesNeed = ["name","timestamp","id"]
todoPropertiesAllowed = ["name","done","description","timestamp","id"]
createId = ()->
    return Date.now().toString()+Math.floor((Math.random()+1)*100000).toString()
compareTodo = (a,b)->
    for prop in todoProperties
        if a[prop] isnt b[prop]
            return false
    return true
# select newer will repair those without timestamp
selectNewer = (a,b)->
    if typeof a.timestamp isnt "number"
        a.timestamp = 0
    if typeof b.timestamp isnt "number"
        b.timestamp = 0
    
    if a.timestamp >= b.timestamp
        return a
    return b

syncFolder = (firstFolder,firstHistory,secondFolder,secondHistory)->
    # sync stratagy overview:
    # conditions
    # 1.A todo appears in both sides,
    # then compare the timestamp use the latter one
    # 2.A todo appreas in one side but not another,
    # then check the log of the side without the todo
    # to see if it was removed by this one

    # Note
    # though not currently implemented
    # the firstFolder's order is actually consider to has priority
    # while we will use some alg to make those in the second folder
    # but not in the first folder to "insert" to the better place
    # which maximum retain the wanted order.
    if firstFolder.name isnt secondFolder.name
        throw new Error("Folder Name Not Match")
    results = {
        name:firstFolder.name,
        todos:[], 
        timestamp:Math.max(firstFolder.timestamp,secondFolder.timestamp)
        }
        
    # by apply mask to secondTodos we skip
    # those todos both appears in firstside and second side
    # latter when we traverse the second todo
    # unmasked item should be the one doesnt appear in firstTodos
    mask = []
    mask.length = secondFolder.todos.length
    for firstTodo in firstFolder.todos
        if not firstTodo.id
            throw new Error "Todo Has No Id"
        if typeof firstTodo.timestamp isnt "number" or isNaN firstTodo.timestamp
            throw new Error "Todo Has No Timestamp"
        hasThisTodo = false
        for secondTodo,index in secondFolder.todos
            
            if not secondTodo.id
                throw new Error "Todo Has No Id"
            if typeof secondTodo.timestamp isnt "number" or isNaN secondTodo.timestamp
                throw new Error "Todo Has No Timestamp"
            if secondTodo.id is firstTodo.id
                # we know this one already exist in first side
                mask[index] = true
                hasThisTodo = true
                if compareTodo(firstTodo,secondTodo)
                    results.todos.push firstTodo
                else
                    results.todos.push selectNewer(firstTodo,secondTodo)
                break
        # first has this todo but second don't
        # so there are some conditions
        # 1.first create this one and has't synced with second
        # 2.another first delete this todo and synced with second 
        if not hasThisTodo
            secondDelete = false
            for log in secondHistory
                if log.todoId is firstTodo.id and log.action is "deleteTodo"
                    # condition 2
                    # this firstodo should be deleted
                    secondDelete = true
                    firstHistory.push log
                    break
            if not secondDelete
                # condition1
                results.todos.push firstTodo
    for secondTodo,index in secondFolder.todos
        if mask[index]
            # appears in the first side and should be already processed
            continue
        # second has todo but first don't have
        # conditions
        # 1.todo is create and synced by another first
        # 2.todo is deleted by first thus should appears in log
        if not secondTodo.id
            throw new Error "Todo Has No Id"
        if typeof secondTodo.timestamp isnt "number" or isNaN secondTodo.timestamp
            throw new Error "Todo Has No Timestamp"
        firstDelete = false
        for log in firstHistory
            if log.todoId is secondTodo.id and log.action is "deleteTodo"
                # condition 2
                secondHistory.push log
                firstDelete = true
                break
        if not firstDelete
            # condition 1
            # we sync this todo to first
            results.todos.push secondTodo
    return results
syncFolders = (first,second)->
    console.assert second.folders instanceof Array
    console.assert first.folders instanceof Array
    for folder in first.folders
        checkFolder(folder)
    for folder in second.folders
        checkFolder(folder)
    folders = []
    mask = []
    mask.length = second.folders.length
    for firstFolder in first.folders
        has = false
        for secondFolder,index in second.folders 
            if secondFolder.name is firstFolder.name
                mask[index] = true
                has = true
                result = syncFolder(firstFolder,first.history,secondFolder,second.history)
                checkFolder result
                folders.push result
                
                break
        if not has
            # first has this folder but second dont
            # looking for log
            solved = false
            for log,index in second.history
                if log.action is "deleteFolder" and log.folderName is firstFolder.name
                    if log.timestamp > firstFolder.timestamp
                        # deleted
                        # dont push to folders
                        solved = true
                        first.history.push log
                    else
                        # out dated log
                        second.history.splice(index,1)
                    break
            if not solved
                # out dated log or log not found
                # folder is recreated/or initially created
                folders.push firstFolder
    for secondFolder,index in second.folders
        if mask[index]
            continue
        
        solved = false
        for log,index in first.history
            if log.action is "deleteFolder" and log.folderName is secondFolder.name
                if log.timestamp > secondFolder.timestamp
                    # deleted
                    # dont push to folders
                    solved = true
                    second.history.push log
                else
                    first.history.splice(index,1)
                break
        if not solved
            # out dated log or log not found
            # folder is recreated/or initially created
            folders.push secondFolder
    return folders
todoProperties
checkTodo = (todo)->
    for prop of todo
        if prop not in todoPropertiesAllowed
            console.error "Invalid Prop",prop
            throw new Error "Broken Todo Message"
    for prop in todoPropertiesNeed
        if todo[prop] is null or typeof todo[prop] is "undefined"
            console.error "todo need prop:",prop
            throw new Error "Broken Todo Message"
    return true
checkFolder = (folder)-> 
    if folder.todos not instanceof Array
        console.log folder
        console.error "Invalid Folder Todos"
        throw new Error "Invalid Folder Todos"
    if typeof folder.name isnt "string"
        console.error "Invalid Folder Name",folder.name
        throw new Error "Invalid Folder Name"
    if typeof folder.timestamp isnt "number"
        throw new Error "Invalid Folder Timestamp"
    for todo in folder.todos
        checkTodo(todo)
            
    
sync = (client,server)->
    for folder in client.folders
        checkFolder(folder)
    if not server.lastSync
        server.lastSync = 0
    if not client.lastSync
        client.lastSync = 0
    if not client.lastUpdate
        client.lastUpdate = 0
    if not server.lastUpdate
        server.lastUpdate = 0
    folders = []
    if client.lastSync is server.lastSync
        # this in MOST case means THE client is the last client
        # synced the server. just set server to client data is OK
        # but considering there some risk for losing data
        # we still use the doing intelligent sync to confirm delete history
        folders = syncFolders(client,server) 
    else if client.lastSync > server.lastSync
        # this is generally not imposible
        # there must be something wrong
        # but just ignore this case 
        folders = syncFolders(client,server) 
        # throw new Error "Broken Client Sync Time"
    else if client.lastSync < server.lastSync
        # somebody else other than this client
        # has synced with server between the last sync of this client
        # so
        if client.lastUpdate <= client.lastSync
            # client didn't change any thing before last sync
            # so the significant modification should from server
            # thus use the serverFolder as the first Folder
            folders = syncFolders(server,client) 
        else
            # though there is another client synced with server
            # between this client's last sync and now
            # this client has change since lastSync
            # this situation is extrodinary hard to 
            # make the right dicision, but the order is highly
            # likely(? why ?) to be synced from the last sync.
            # so we still use serverFolder as the first folder
            folders = syncFolders(server,client)
        # use synced folders but keep own history
        # (history is modified/partially-synced during folder sync)
    client.folders = folders
    server.folders = folders
    client.lastSync = Date.now()
    server.lastSync = client.lastSync
    client.lastUpdate = Math.max(server.lastUpdate,client.lastUpdate)
    server.lastUpdate = client.lastUpdate
    return true
exports.syncFolders = syncFolders
exports.sync = sync
exports.syncFolder = syncFolder
exports.createId = createId







