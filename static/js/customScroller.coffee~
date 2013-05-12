class CustomScroller extends Leaf.Widget
    constructor:()->
        super(Site.templates["custom-scroller"])
        @scrollerPosition = 0
        @UI.scroller.onmousedown = (e)=>
            @startDrag = true
            @startPoint =  [e.pageX,e.pageY]
            @startTop = parseInt @UI.scroller.style.top.replace("px","") or 0
            e.preventDefault() 
            e.stopPropagation()
            return false
            $("body").addClass("no-select")
        window.addEventListener "mouseup",(e)=>
            if @startDrag
                e.preventDefault()
                e.stopPropagation()
            @startDrag = false
            @startPoint = null
            $("body").removeClass("no-select"); 
            return false
        window.addEventListener "mousemove",(e)=>
            if not @startDrag
                return true
            e.preventDefault()
            top = @startTop + e.pageY - @startPoint[1]
            if top < 0
                top = 0
            if top > $(@parent).height()-@UI.scroller$.height()
                top = $(@parent).height()-@UI.scroller$.height()
            @UI.scroller$.css({top:top})
            @scrollerPosition = top
            @parent.scrollTop = top / @scaleRatio
            return false
        @node$.mousedown (e)=>
            if e.offsetY > @scrollerPosition
                @parent.scrollByPages 1
            if e.offsetY < @scrollerPosition 
                @parent.scrollByPages -1
        
    attachTo:(node)->
        @parent = node
        @appendTo @parent
        node.onscroll = @onScroll.bind this
        node.onresize = @resize.bind this
        @resize()
        $(window).resize(@resize.bind this)
    onScroll:()->
        @resize()
        @UI.scroller$.css({top:@parent.scrollTop*@scaleRatio})
        @scrollerPosition = @parent.scrollTop*@scaleRatio
    resize:()->
        @scaleRatio = $(@parent).height()/@parent.scrollHeight
        @node$.css({height:$(@parent).height()})
        @UI.scroller$.height(@scaleRatio*$(@parent).height()) 
    
        
window.CustomScroller = CustomScroller