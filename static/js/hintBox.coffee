class Hint extends Leaf.Widget
    constructor:()->
        super(App.templates["hint"])
    show:(text,type)-> 
        @UI.content.innerHTML = text
        @node.style.display = "none"
        if type is "Error"
            @UI.type.innerHTML = "惊" 
            @UI.type.style.color = "#c00" 
        else
            @UI.type.style.color = "white"
            @UI.type.style.backgroundColor = "none"
            @UI.type.innerHTML = "注"
        @$node.slideDown()
    hide:()->
        @$node.slideUp(()=>@remove())
class HintBox extends Leaf.Widget
    constructor:()->
        super(App.templates["hint-box"])
        #@appendTo document.body
        
    show:(text,type)->
        hint = new Hint()
        hint.prependTo(this)
        hint.show(text,type)
        setTimeout(()->
            hint.hide()
        ,8000)

window.HintBox = HintBox 