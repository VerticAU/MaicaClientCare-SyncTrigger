({
    handleShowProgress: function (cmp, event, helper) {
        helper.initColumns(cmp);

        if(cmp.get('v.jobId')){
            cmp.set('v.progress', 0);
            cmp.set('v.stage', 'pending');
            cmp.set('v.job', null);
            // cmp.set('v.meta.errors', null);
            helper.updateStatus(cmp, event, helper);
        }
    },

    handleJobProcessedChange: function(cmp, event, helper){
        var errorsTableCmp = cmp.find('errorsTable');
        if(errorsTableCmp){
            errorsTableCmp.refresh();
        }
    },

    handleCloseClick: function (cmp, event, helper) {
        cmp.set('v.stage', 'initial');
        cmp.set('v.meta.showMoreErrorDetails', false);
    },
})