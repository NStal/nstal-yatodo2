class FocusList extends Leaf.Widget 
    constructor:(template)->
        super(template)
        @items = []
    addItem:(item)->
        @bindItem(item)
        @appendItem(item)
    bindItem:(item)->
        item.on "focus",()=>
            @currentFocusItem = item
            for todo in @items
                if todo isnt item
                    todo.unfocus()
        @emit "focus",item
    appendItem:(item)->
        @items.push item
        item.appendTo @node
    removeItem:(item)->
        pos = @items.indexOf(item)
        if pos >= 0
            @items.splice(pos,1)
            item.remove()
            return item
        return null
    indexOfItem:(item)->
        return @items.indexOf(item)
    nextItem:(item)->
        index = @items.indexOf(item)
        if index <  0
            return null
        if index >= 0
            if @items[index+1] 
                return @items[index+1]
            else
                return @items[0]
        else
            return null
    previousItem:(item)->
        index = @items.indexOf(item)
        if index <  0
            return null
        if index >= 1
            return @items[index-1]
        else
            return @items[@items.length-1]
    insertItem:(item,index)->
        if index < 0
            index = 0
        if index < @items.length 
            item.before @items[index]
            @items.splice(index,0,item)
        else if @items.length-1 >= 0
            item.after @items[@items.length-1]
            @items.push item
        else
            item.appendTo @node
            @items.push item
        return item

class FocusListItem extends Leaf.Widget
    focus:()->
        if @isFocus
            return false
        @isFocus = true
        @emit "focus"
        @node$.addClass("focus")
        return true
    unfocus:()-> 
        if not @isFocus
            return false
        @isFocus = false
        @emit "unfocus"
        @node$.removeClass("focus")
        return true
window.FocusListItem = FocusListItem
window.FocusList = FocusList