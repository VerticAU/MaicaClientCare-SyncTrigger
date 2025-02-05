({
    handleInit: function(cmp, event, helper){
        cmp.find('tabset').set('v.selectedTabId', window.localStorage.getItem('settingsSelectedTabId') || 'syncManagement');

        cmp.set('v.isSystemAvailable', new URLSearchParams(window.location.hash.replace("#","?")).get('admin') === 'true')
    },

    handleTabSelect: function(cmp, event, helper){
        if(cmp.find('tabset').get('v.selectedTabId') === 'admin'){
            return; //Don't store Admin as default tab.
        }
        window.localStorage.setItem('settingsSelectedTabId', cmp.find('tabset').get('v.selectedTabId'));
    }
});