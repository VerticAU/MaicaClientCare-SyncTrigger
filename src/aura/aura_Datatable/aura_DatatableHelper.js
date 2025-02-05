({
    getCmp: function (cmp) {
        let datatableCmp = cmp.find('datatable');
        if(!datatableCmp){
            throw 'No datatable';
        }
        return datatableCmp;
    },

    sort: function (records, sortBy, direction) {

        var dateFormat = /^\d{4}-\d{2}-\d{2}$/;
        var dateTimeFormat = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/;

        var sortedRecords =_.sortBy(JSON.parse(JSON.stringify(records)), function (record) {

            var value = record[sortBy];

            if (typeof value === "string" && (dateFormat.test(value) || dateTimeFormat.test(value))) {
                return new Date(value);
            }

            return value;
        });

        if(direction == 'desc'){
            sortedRecords.reverse();
        }

        return sortedRecords;

    },

    fireOnSortEvent: function (cmp, event, helper, fieldName, sortDirection) {
        var datatableCmp = helper.getCmp(cmp);

        var columns = datatableCmp.get('v.columns') || [];
        var column = helper.getColumnByFieldName(columns, fieldName);
        if (column) {
            var onSortEvent = cmp.getEvent('onSort');
            onSortEvent.setParams({
                'payload': {
                    'column' : column,
                    'direction': sortDirection
                }
            });
            onSortEvent.fire();
        }
    },

    getColumnByFieldName: function(columns, fieldName) {
        for (var i = 0; i < columns.length; i++) {
            if (columns[i].fieldName === fieldName) {
                return columns[i];
            }
        }
        return null;
    }
})