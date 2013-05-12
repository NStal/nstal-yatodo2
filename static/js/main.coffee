window.App = window
window.Plugins = []
$ ()->
    templateManager = new Leaf.TemplateManager()
    templateManager.use "todo-list-item","todo-list","action-bar","todo-list-header","folder-list-item","hint","hint-box","signup-box","signin-box","message-box","help-box","custom-scroller"
    templateManager.on "ready",(templates)->
        App.templates = templates
        App.userInfoManager = new UserInfoManager()
        App.dataManager = new DataManager()

        App.yatodo = new Yatodo()

        App.yatodo.init()
    templateManager.start()
    
DefaultData = [{name:"FolderA",todos:[{name:"A:My Todo"},{name:"A:My Todo2"}]},{name:"FolderB",todos:[{name:"B:My Todo"},{name:"B:My Todo2"}]}]

class Yatodo extends Leaf.Widget
    constructor:()->
        @todoList = new TodoList()
        @todoListHeader = new TodoListHeader()
        @actionBar = new ActionBar()
        @hintBox = new HintBox()
        @signupBox = new SignupBox()
        @signinBox = new SigninBox()
        @helpBox = new HelpBox()
        @todoListHeader.on "goto",(folder)=>
            if @todoList.currentFocusItem and @todoList.currentFocusItem.isEdit
                @todoList.currentFocusItem.endEdit()
            @todoList.set folder
        @todoListHeader.on "createFolder",(folder)=>
            if not App.dataManager.createFolder(folder)
                return
            @todoListHeader.set App.dataManager.data.folders
        @todoListHeader.set App.dataManager.data.folders
        @todoListHeader.goto()
        super("#yatodo")
        @initHotkey()
        @todoList.on "change",(type,object)=>
            console.log "change!",type,object
            App.dataManager.setFolderData(@todoList.toData())
            if type is "delete"
                App.dataManager.addHistory {action:"deleteTodo",todoId:object.data.id}
        App.dataManager.on "synced",()=>
            folder = App.dataManager.getFolder(@todoList.data)
            @todoListHeader.set App.dataManager.data.folders
            if not Leaf.Util.compare(@todoList.data,folder)
                console.log @todoList.data,folder,"!!!"
                @todoListHeader.goto folder
            else
                for item in @todoListHeader.items
                    if item.folder.name is folder.name
                        item.focus()
                        return
            
    loadPlugins:()->
        for plugin in window.Plugins
            plugin.load()
    init:()->
        @loadPlugins()
        App.userInfoManager.on "signin",()=>
            @signupBox.hide()
            @signinBox.hide()
            @hint Language.welcomeAboard
        App.userInfoManager.on "failToSignin",()=>
            @hint Language.wrongUsernameOrPassword
        @emit "ready"
    hint:(str)->
        @hintBox.show str
    warn:(str)-> 
        @hintBox.show str,"Error"
    suggestSignin:()->
        if not @alreadySuggest
            @requireSignin()
            @alreadySuggest = true
    requireSignin:()->
        @signinBox.show()
    fullScreen:()->
        @node$.addClass "full-screen"
        @isFullScreen = true
    halfScreen:()->
        @node$.removeClass "full-screen"
        @isFullScreen = false
    deleteCurrentFolder:()->
        if @todoList.data.todos.length is 0 or confirm(Language.confirmDeleteFolder) 
            if App.dataManager.deleteFolder(@todoList.data)
                @.todoListHeader.set(App.dataManager.data.folders)
                @.todoListHeader.gotoFirstFolder()
            
    initHotkey:()->
        #end test
        @km = new Leaf.KeyEventManager()
        @km.attachTo(window)
        @km.master()
        @km.on "keydown",(e)=>
            if e.which is Leaf.Key.h and e.altKey
                @helpBox.show()
                e.capture()
                return
            if e.which is Leaf.Key.right and e.ctrlKey
                @todoListHeader.nextFolder()
                e.capture()
                return
            if e.which is Leaf.Key.left and e.ctrlKey
                @todoListHeader.previousFolder()
                e.capture()
                return
            if e.which is Leaf.Key.down and e.ctrlKey
                @todoListHeader.showFolderList()
                e.capture()
                return

            if e.which is Leaf.Key.enter and e.ctrlKey and e.altKey
                @todoList.createNewItemBelow()
                e.capture()
                return
            
            if e.which is Leaf.Key.enter and e.ctrlKey
                @todoList.createNewItem()
                e.capture()
                return
            if e.which is Leaf.Key.up and e.altKey
                @todoList.moveFocusToPrevious()
                e.capture()
                return
            if e.which is Leaf.Key.down and e.altKey
                @todoList.moveFocusToNext()
                e.capture()
                return
            if e.which is Leaf.Key.enter
                if @todoList.currentFocusItem
                    @todoList.currentFocusItem.startEdit()
                e.capture()
                return
            if e.which is Leaf.Key.down or e.which is Leaf.Key.k
                next = @todoList.nextItem @todoList.currentFocusItem
                e.capture()
                if next
                    console.log "has Next"
                    next.focus()
                return
            if e.which is Leaf.Key.up or e.which is Leaf.Key.j
                prev = @todoList.previousItem @todoList.currentFocusItem
                if prev then prev.focus()
                e.capture()
                return
            if e.which is Leaf.Key.space
                if @todoList.currentFocusItem.isEdit
                    return 
                @todoList.toggleCurrentFocus()
                e.capture()
                return
            if e.which is Leaf.Key.del and e.ctrlKey
                @deleteCurrentFolder()
                e.capture()
            if e.which is Leaf.Key.backspace and e.ctrlKey
                if @todoList.currentFocusItem and @todoList.currentFocusItem.isEdit
                    return 
                @todoList.deleteFocus()
                e.capture()
                return
            if e.which is Leaf.Key.s and e.altKey
                App.dataManager.remoteSync()
                e.capture()
                return
            if e.which is Leaf.Key.r and e.altKey
                @todoList.deleteDone()
                e.capture()
                return
            if e.which is Leaf.Key.c and e.altKey
                @todoList.moveDoneToBottom()
                e.capture()
                return
                
class ActionBar extends Leaf.Widget
    constructor:()-> 
        super App.templates["action-bar"]
        App.dataManager.on "syncStart",()=>
            @UI.syncButton$.addClass "icon-spin"
        App.dataManager.on "syncEnd",()=>
            @UI.syncButton$.removeClass "icon-spin"
    onClickSyncButton:()->
        App.dataManager.remoteSync()
    onClickCreateTodoButton:()-> 
        App.yatodo.todoList.createNewItem()
    onClickResizeButton:()->
        if App.yatodo.isFullScreen
            App.yatodo.halfScreen()
        else
            App.yatodo.fullScreen()
        App.yatodo.todoList.resize()
    onClickSignoutButton:()->
        App.userInfoManager.signout() 
    onClickHelpButton:()->
        App.yatodo.helpBox.show()
class TodoList extends FocusList
    constructor:()->
        super App.templates["todo-list"]
        @items = []
        @data = null
        @scroller = new CustomScroller()
        @scroller.attachTo(@node)
        @resize()
    set:(data)->
        @clear()
        @data = data
        for todoInfo in @data.todos
            @addItem new TodoListItem(todoInfo)
        if @items.length > 0
            @items[0].focus()
        @reorder()
    resize:()->
        @node$.css({height:$(".todo-list-container").height()-48})
        @scroller.resize()
    clear:()->
        @data = null
        for item in @items
            item.remove()
        @items.length = 0
    toData:()->
        if not @data
            return null
        todos = []
        for todo in @items
            todos.push todo.toData()
        return {name:@data.name,todos:todos,timestamp:@data.timestamp}
    deleteFocus:()->
        if not @currentFocusItem
            return false
        if @items.length isnt 1
            nextFocus = @nextItem(@currentFocusItem) or @previousItem(@currentFocusItem)
        else
            nextFocus = null
        @deleteItem(@currentFocusItem)
        if nextFocus and (nextFocus isnt @currentFocusItem)
            nextFocus.focus()
        else
            @currentFocusItem = null
        @reorder()
    deleteDone:()->
        dones = @items.filter (item)->item.data.done
        for item in dones
            @deleteItem(item)
        if @items[0]
            @items[0].focus()
            
    deleteItem:(item)->
        @removeItem(item)
        @emit "change","delete",item
    createNewItem:()->
        # create doesnt emit change
        # unless it's edit to an not default value
        # by default it's create at above the current focus
        newItem = new TodoListItem()
        @bindItem(newItem)
        index = @indexOfItem(@currentFocusItem)
        if index > 0
            @insertItem newItem,index
        else
            @insertItem newItem,0
        newItem.focus()
        newItem.startEdit()
    createNewItemBelow:()->
        newItem = new TodoListItem()
        @bindItem(newItem)
        index = @indexOfItem(@currentFocusItem)
        if index > 0
            @insertItem newItem,index+1
        else
            @insertItem newItem,1
        newItem.focus()
        newItem.startEdit()
    addItem:(item)->
        @bindItem(item)
        @appendItem(item)
    bindItem:(item)->
        super(item)
        item.on "focus",()=>
            @scrollToSeeItem item
        item.on "change",(args...)=>
            args.splice(0,0,"change")
            @emit.apply this,args
            
    appendItem:(item)->
        result = super(item)
        item.appendTo @node
        @reorder()
        return result
    removeItem:(item)->
        result = super(item)
        @reorder()
        return result
    insertItem:(item,index)->
        result = super(item,index)
        @reorder()
        return result    
    reorder:()->
        # setTimeout to get corrent item height
        setTimeout (()=>
            if @items.length is 0
                return
            top = 1
            border = 1
            step = @items[0].node$.height() + border
            for item in @items
                item.node$.css({top:top})
                top += step
            @scroller.resize()
            ),0
        
    scrollToSeeItem:(todo)->
        todoIndex = -1
        for item,index in @items
            if item is todo
                todoIndex = index
        console.assert todoIndex isnt -1
        todoHeight = todo.$node.height()+1
        todoTop = todoIndex * todoHeight + 1
        todoBottom = todoTop + todoHeight
        viewableTop = @node.scrollTop
        viewableBottom = viewableTop+@node$.height()
        
        # extraScroll Allowed User to 
        extraScroll = 20
        # console.log todoHeight,todoTop,todoBottom,viewableTop,viewableBottom
        if todoBottom > viewableBottom
            # console.log todoBottom,viewableBottom
            @node.scrollTop += todoTop-viewableBottom+todoHeight+extraScroll
            return true
        if todoTop < viewableTop
            @node.scrollTop -= viewableTop-todoBottom+todoHeight+extraScroll
            return true
    moveFocusToNext:()->
        if not @currentFocusItem
            return
        index = @indexOfItem(@currentFocusItem)+1
        @removeItem(@currentFocusItem)
        @insertItem(@currentFocusItem,index)
        @emit "change","reorder"
    moveFocusToPrevious:()->
        if not @currentFocusItem
            return
        index = @indexOfItem(@currentFocusItem)-1
        @removeItem(@currentFocusItem)
        @insertItem(@currentFocusItem,index)
        @emit "change","reorder"
    toggleCurrentFocus:()->
        if @currentFocusItem
            @currentFocusItem.onClickDoneCheckbox()
    moveDoneToBottom:()->
        dones = @items.filter (item)->item.data.done
        if dones.length is 0
            return
        for item in dones
            @removeItem(item)
            @insertItem(item,@items.length)
        @emit "change","reorder"
class TodoListItem extends FocusListItem
    constructor:(data)->
        super(App.templates["todo-list-item"])
        # make sure has id and timestamp
        @defaultName = ""
        @nonameHolder = "no name"
        @originalData = data or {
            timestamp:Date.now(),
            name:@defaultName,
            description:"",
            id:Date.now().toString()+Math.floor((Math.random()+1)*100000).toString()
        }
        @data = Leaf.Util.clone(@originalData)
        @render()
        @km = new Leaf.KeyEventManager()
        @km.attachTo window
        @km.on "keydown",(e)=>
            if @isEdit and e.which is Leaf.Key.enter or e.which is Leaf.Key.escape
                @endEdit()
                e.capture()
                return

    unfocus:()->
        @endEdit()
        return super()
    toData:()->
        if Leaf.Util.compare @data,@originalData
            return @data
        @data.timestamp = Date.now()
        return @data
    render:()->
        @UI.$todoName.text(@data.name or @nonameHolder)
        @UI.$todoDescriptionSummery.text(@data.description or "")
        if @data.done
            @done()
        else
            @undone()
    done:()->
        if @isEdit
            # can't change while editing
            return false
        
        @$node.addClass("done")
        @UI.$doneCheckbox.addClass("icon-ok")
        if not @data.done
            @data.done = true
            @emit "change","done",this
            return true
        return false
    
    undone:()->
        if @isEdit
            # can't change while editing
            return false
        @$node.removeClass("done")
        @UI.$doneCheckbox.removeClass("icon-ok")
        if @data.done
            delete @data.done
            @emit "change","undone",this
            return true
        return false
    onMouseoverNode:()->
        @focus()
    onClickDoneCheckbox:()->
        if @data.done
            @undone()
        else
            @done()
    onClickTodoName:()->
        @startEdit()    
    onBlurTodoNameInput:()->
        @endEdit()
    onKeydownTodoNameInput:(e)->
    toDetail:()->
        if not @isDetail
            @$node.addClass "detailed"
            @emit("detail")
            @isDetail = true
    unDetail:()->
        if @isDetail
            @$node.removeClass "detailed"
            @isDetail = false
    startEdit:()->
        # Not Allowed to edit done todo
        if @data.done
            return
        if not @isEdit
            @isEdit = true
        else
            return
        @km.master()
        @UI.$todoName.hide()
        #@UI.todoNameInput.removeAttribute("disable")
        @UI.$todoNameInput.show()
        @UI.$todoNameInput.val(@data.name)
        @UI.$todoNameInput.focus()
    endEdit:()->
        if @isEdit
            @isEdit = false
        else
            return
        @km.unmaster()
        @UI.$todoName.show()
        @UI.$todoNameInput.hide()
        newName = @UI.$todoNameInput.val()
        if not newName
            newName = @defaultName
        if newName isnt @data.name
            @data.name = newName
            @emit "change"
            @render()
    getCaretPosition:()->
        return window.getSelection().getRangeAt().startOffset

class FadeBox extends Leaf.Widget
    constructor:(template)->
        super(template)
        @isShown = false
    show:()->
        if @isShown
            return
        @isShown = true
        @node$.fadeIn()
        $(".solid-content").addClass("blur")
    hide:()->
        if not @isShown
            return
        @isShown = false
        @node$.fadeOut() 
        $(".solid-content").removeClass("blur")
window.FadeBox = FadeBox