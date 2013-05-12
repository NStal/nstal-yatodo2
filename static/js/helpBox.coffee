class HelpBox extends FadeBox
    constructor:()->
        console.log App
        super(App.templates["help-box"])
        @km = new Leaf.KeyEventManager()
        @km.attachTo window
        @km.on "keydown",(e)=>
            if e.which is Leaf.Key.escape
                e.capture()
                @hide()
                return
    show:()->
        super()
        @km.master()
    hide:()->
        super()
        @km.unmaster()


window.HelpBox = HelpBox