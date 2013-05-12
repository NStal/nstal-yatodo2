class SaveAndReloadUserState
    constructor:()->
        # pass
    load:()->
        console.log "~~~"
        localStorageCurrentFolder = "SaveAndReloadUserState-currentFolder"
        App.yatodo.todoListHeader.on "goto",(folder)->
            if localStorage
                localStorage.setItem(localStorageCurrentFolder,folder.name)
        App.yatodo.on "ready",()->
            if localStorage
                folderName = localStorage.getItem(localStorageCurrentFolder)
                if folderName
                    for folder in App.dataManager.data.folders
                        if folder.name is folderName
                            App.yatodo.todoListHeader.goto folder
                    
        
    unload:()->
        
Plugins.push new SaveAndReloadUserState() 