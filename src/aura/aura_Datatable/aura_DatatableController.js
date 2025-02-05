({
    handleInit: function (cmp, event, helper) {
        var datatableCmp = helper.getCmp(cmp);
        var attributes = cmp.get('v.attributes') || {};
        for(var attr in attributes){
            datatableCmp.set('v.' + attr, attributes[attr]);
        }
    },

    handleScriptsLoaded: function (cmp, event, helper) {
        var datatableCmp = helper.getCmp(cmp);
        var onAfterDatatableLoad = cmp.getEvent('onAfterDatatableLoad');
        onAfterDatatableLoad.setParams({
            'payload': {
                'isLoaded' : true
            }
        });
        onAfterDatatableLoad.fire();
    },
    handleSetAttr: function (cmp, event, helper) {

        var datatableCmp = helper.getCmp(cmp);

        var params = event.getParam('arguments');

        var attr = params.attr;
        var val = params.val;

        datatableCmp.set(attr, val);

        return cmp;
    },

    handleSetData: function (cmp, event, helper) {
        var datatableCmp = helper.getCmp(cmp);

        var params = event.getParam('arguments');

        var records = params.records;

        var flattenRecords = records.map(function (record) {
            return cmp.utils.flatten(record);
        });

        cmp.set('v.data', flattenRecords);

        var isNoRecords = !flattenRecords || flattenRecords.length == 0;

        cmp.set('v.showNoRecordsMessage', isNoRecords);

        var showNoRecordsHeaders = cmp.get('v.showNoRecordsHeaders');
        if(isNoRecords === true){
            if (showNoRecordsHeaders == false) {
                $A.util.addClass(cmp.find('datatableContainer'), 'slds-hide');
            }
        } else {
            if (showNoRecordsHeaders == false) {
                $A.util.removeClass(cmp.find('datatableContainer'), 'slds-hide');
            }
            cmp.sort();
        }

        return cmp;
    },

    handleOnSort: function (cmp, event, helper) {
        var datatableCmp = helper.getCmp(cmp);

        cmp.set('v.showSpinner', true);

        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        datatableCmp.set("v.sortedBy", fieldName);
        datatableCmp.set("v.sortedDirection", sortDirection);

        var sortedData = helper.sort(cmp.get('v.data'), fieldName, sortDirection);
        cmp.set('v.data', sortedData);

        helper.fireOnSortEvent(cmp, event, helper, fieldName, sortDirection);

        cmp.set('v.showSpinner', false);
    },

    handleSort: function (cmp, event, helper) {
        var datatableCmp = helper.getCmp(cmp);

        cmp.set('v.showSpinner', true);

        var fieldName = datatableCmp.get("v.sortedBy");
        var sortDirection = datatableCmp.get("v.sortedDirection");

        var sortedData = helper.sort(cmp.get('v.data'), fieldName, sortDirection);
        cmp.set('v.data', sortedData);

        helper.fireOnSortEvent(cmp, event, helper, fieldName, sortDirection);

        cmp.set('v.showSpinner', false);
    },

    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');

        if(action.doAction){

            setTimeout($A.getCallback(function () {
                action.doAction(row);
            }));

        } else {
            throw 'No do Action'
        }
    },

    handleRowSelection: function (cmp, event, helper) {
        var onRowSelectionEvent = cmp.getEvent('onRowSelection');
        onRowSelectionEvent.setParams({
            'payload': {
                'selectedRows' : event.getParam('selectedRows'),
            }
        });
        onRowSelectionEvent.fire();
    },

    handleGetSelectedRows: function (cmp, event, helper) {
        var datatableCmp = helper.getCmp(cmp);
        return datatableCmp.getSelectedRows();
    }


})