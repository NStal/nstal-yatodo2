class SyncPeriodically
    constructor:()->
        @timer = null
        @syncInterval = 1000 * 60 * 10
    load:()->
        console.log "Plugin Sync Periodically Loaded"
        @timer = setInterval (()->
            App.yatodo.actionBar.onClickSyncButton()
            ),@syncInterval
    unload:()->
        clearInterval(@timer)
Plugins.push new SyncPeriodically()