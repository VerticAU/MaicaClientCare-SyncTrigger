({
    handleInit: function(cmp, event, helper){
        helper.retrieveData(cmp, event, helper).then(function (value) {
            helper.onAfterSOQLDatatableLoadEventFire(cmp, event, helper);
            return value;
        });
    },

    handleRefresh: function (cmp, event, helper) {
        return new Promise($A.getCallback(function (resolve, reject) {
            helper.retrieveData(cmp, event, helper)
                .then(function (data) {
                    helper.onAfterSOQLDatatableRefreshEventFire(cmp, event, helper);
                    resolve(data);
                })
                .catch(function (errors) {
                    reject(errors);
                });
        }));
    },

    handleConditionChange: function(cmp, event, helper) {
        cmp.refresh();
    }

})