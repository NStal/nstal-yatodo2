class TodoListHeader extends FocusList 
    constructor:()->
        super App.templates["todo-list-header"]
        @km = new Leaf.KeyEventManager()
        @km.attachTo window
        @km.on "keydown",(e)=>
            if e.which is Leaf.Key.escape
                @hideFolderList()
                e.capture()
                return
            if e.which is Leaf.Key.up and e.ctrlKey
                @hideFolderList()
                e.capture()
                return
            if e.which is Leaf.Key.up
                @previousFolder()
                e.capture()
                return
            if e.which is Leaf.Key.down
                @nextFolder()
                e.capture()
                return
            if e.which is Leaf.Key.enter
                if @isEdit
                    @createFolderByCurrentEdit()
                else
                    @hideFolderList()
                e.capture()
                return
            if e.which >= Leaf.Key.a and e.which <= Leaf.Key.z and not @isEdit
                console.log @isEdit
                alphabet = "abcdefghijklmnopqrstuvwxyz"
                @handleCharactorNavigate(alphabet[e.which-Leaf.Key.a])
                e.capture()
                return

    handleCharactorNavigate:(char)->
        @lastParseFolderName = @lastParseFolderName or null
        @lastNavigationString = @lastNavigationString and @lastNavigationString+char or char
        for item in @items
            pinyin = Pinyin.toPinyin(item.folder.name).toLowerCase()
            console.log @lastNavigationString
            if pinyin.indexOf(@lastNavigationString) is 0
                item.focus()
                @goto(item.folder)
                return
        # reset lastNavigationString and try again
        @lastNavigationString = char
        for item in @items
            pinyin = Pinyin.toPinyin(item.folder.name).toLowerCase()
            console.log @lastNavigationString
            if pinyin.indexOf(@lastNavigationString) is 0
                item.focus()
                @goto(item.folder)
                return
        # not found
            
    set:(folders)->
        console.assert folders instanceof Array
        @folders = folders
        for item in @items
            item.remove()
        @items.length = 0
        for item in @folders
            item = new FolderListItem(item)
            @bindItem(item)
            @appendItem(item)
            item.appendTo @UI.folderList
            
        #if @folders.length
        #    @goto @folders[0]
    bindItem:(item)->
        super(item)
        item.onClickNode = ()=>
            @hideFolderList()
            @goto item
    gotoFirstFolder:()->
        if @folders.length
            @goto @folders[0]
    goto:(targetFolder)->
        if not targetFolder and @items[0]
            targetFolder = @items[0].folder
        for folder in @items
            if folder.name is targetFolder.name
                @UI.folderName$.text folder.name
                @emit "goto",folder.folder
                folder.focus()
                return folder
        throw new Error "goto folder not exists"
        return null
    startEditCreateFolder:()->
        if @isEdit
            return
        @isEdit = true
        @UI.createText$.hide()
        @UI.folderNameInput$.show()
        @UI.folderNameInput$.focus()
    endEditCreateFolder:()->
        if not @isEdit
            return
        @isEdit = false
        @UI.createText$.show()
        @UI.folderNameInput$.blur()
        @UI.folderNameInput$.hide()
    nextFolder:()->
        item = @nextItem(@currentFocusItem)
        if item
            item.focus()
            @goto(item)
    previousFolder:()->
        item = @previousItem(@currentFocusItem)
        if item
            item.focus()
            @goto(item)
    showFolderList:()->
        if @isShown
            return
        @isShown = true
        @km.master()
        @UI.folderList$.show() 
    hideFolderList:()->
        if not @isShown
            return
        @isShown = false
        @km.unmaster()
        @UI.folderList$.hide()
        @endEditCreateFolder()
    createFolderByCurrentEdit:()->
        folderName = @UI.folderNameInput$.val().trim()
        folder = {
            name:folderName,
            timestamp:Date.now()
            todos:[]
            }
        @emit "createFolder",folder
        @UI.folderNameInput.value = ""
        @endEditCreateFolder()
    onClickNextFolderButton:()->
        @nextFolder()
    onClickPreviousFolderButton:()->
        @previousFolder()
    onClickFolderName:()->
        if @isShown
            @hideFolderList()
        else
            @showFolderList()
    onClickCreateText:()->
        @startEditCreateFolder()
class FolderListItem extends FocusListItem
    constructor:(data)->
        super App.templates["folder-list-item"]
        @name = data.name
        @folder = data
        @node$.text(data.name)
window.TodoListHeader = TodoListHeader