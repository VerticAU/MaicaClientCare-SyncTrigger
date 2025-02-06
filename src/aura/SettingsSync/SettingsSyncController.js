({
    handleSaveClick: function (cmp, event, helper) {
        if (!cmp.validate()) {
            return;
        }

        cmp.set('v.hideContentOnBusy', false);

        helper
            .submit(cmp, helper)
            .then(response => {
                let proc = cmp.find('syncSupportItemsProcessor') || cmp.find('syncProductsProcessor') || cmp.find('syncEntriesProcessor');
                if(proc){
                    proc.setStage('initial');
                }
                cmp.set('v.isEdit', false);
                return helper.init(cmp);
            });
    },

    handleSyncSupportItems: function (cmp, event, helper) {
        if (!cmp.validate()) {
            return;
        }

        cmp.set('v.hideContentOnBusy', false);

        helper.submit(cmp, helper)
            .then(response => {
                return cmp.find('syncSupportItemsProcessor').process(
                    'SyncSupportItemsBatch', {}
                )
            });
    },

    handleSyncSupportItemsComplete: function (cmp, event, helper) {
        let payload = event.getParam('payload');
        if (payload && payload.success) {
            $A.enqueueAction(cmp.get('c.handleSyncPriceLists'));
        }
    },

    handleSyncPriceLists: function (cmp, event, helper) {
        cmp.find('syncPriceListsProcessor').process(
            'SyncPriceListsBatch', {}
        );
    },

    handleSyncPriceListsComplete: function (cmp, event, helper) {
        let payload = event.getParam('payload');
        if (payload && payload.success) {
            $A.enqueueAction(cmp.get('c.handleSyncPriceListEntries'));
        }
    },

    handleSyncPriceListEntries: function (cmp, event, helper) {
        let proc = cmp.find('syncPriceListEntriesProcessor');

        if(proc && $A.util.isArray(proc)){
            proc = proc[0];
        }

        if (proc) {
            proc.process(
                'SyncPriceListEntriesBatch', {}
            );
        } else {
            proc = cmp.find('syncEntriesProcessor');
            if (proc) {
                if (!cmp.validate()) {
                    return;
                }

                cmp.set('v.hideContentOnBusy', false);

                helper.submit(cmp, helper)
                    .then(response => {
                        return proc.process(
                            'SyncPriceListEntriesBatch', {}
                        );
                    });
            }
        }
    },

    handleSyncPriceListEntriesComplete: function (cmp, event, helper) {
        let payload = event.getParam('payload');
        if (payload && payload.success) {
            cmp.find('notifLib').showToast({
                variant: 'success',
                message: 'Sync Completed!'
            });
        }
    },

    handleSyncProducts: function (cmp, event, helper) {
        if (!cmp.validate()) {
            return;
        }

        cmp.set('v.hideContentOnBusy', false);

        helper.submit(cmp, helper)
            .then(response => {
                return cmp.find('syncProductsProcessor').process(
                    'SyncProductsBatch', {}
                )
            })
    },

    handleSyncProductsComplete: function (cmp, event, helper) {
        let payload = event.getParam('payload');
        if (payload && payload.success) {
            $A.enqueueAction(cmp.get('c.handleSyncPricebooks'));
        }
    },

    handleSyncPricebooks: function (cmp, event, helper) {
        cmp.find('syncPricebooksProcessor').process(
            'SyncPricebooksBatch', {}
        )
    },

    handleSyncPricebooksComplete: function (cmp, event, helper) {
        let payload = event.getParam('payload');
        if (payload && payload.success) {
            $A.enqueueAction(cmp.get('c.handleSyncPricebookEntries'));
        }
    },

    handleSyncPricebookEntries: function (cmp, event, helper) {
        let proc = cmp.find('syncPricebookEntriesProcessor');

        if(proc && $A.util.isArray(proc)){
            proc = proc[0];
        }

        if(proc){
            cmp.find('syncPricebookEntriesProcessor').process(
                'SyncPricebookEntriesBatch', {}
            )
        }
    },

    handleSyncPricebookEntriesComplete: function (cmp, event, helper) {
        let payload = event.getParam('payload');
        if (payload && payload.success) {
            cmp.find('notifLib').showToast({
                variant: 'success',
                message: 'Sync Completed!'
            });
        }
    },
});