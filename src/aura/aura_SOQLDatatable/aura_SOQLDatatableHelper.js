({
    retrieveData: function (cmp, event, helper) {

        return new Promise($A.getCallback(function (resolve, reject) {

            var timestamp = Date.now();
            cmp.set('v.timestamp', timestamp);

            var orderFields = cmp.get('v.orderBy') || '';
            var orderFieldsArray = orderFields.split(',');
            var order = [];

            orderFieldsArray.forEach(function (field) {
                if (field.startsWith(' ')) {
                    field = field.substring(1);
                }
                if (field.endsWith(' ')) {
                    field = field.substring(0, field.length - 1);
                }
                var params = field.split(' ');
                order.push({
                    "field": params[0],
                    "order": params[1] || 'ASC',
                    "nulls": params[2] && params[3] ? params[2] + ' ' + params[3] : 'NULLS FIRST'
                });
            });

            var request = {
                sObjectType: cmp.get('v.sObjectType'),
                fields: cmp.get('v.fields'),
                condition: cmp.get('v.condition'),
                timestamp: timestamp,
                limit: cmp.get('v.limit'),
                orderBy: order,
                wrapText: cmp.get('v.wrapText')
            };

            var dataTableCmp = cmp.getSuper();
            dataTableCmp.set('v.showSpinner', true);

            helper.execute(
                cmp,
                cmp.get('v.processor'),
                request,
                function (response) {
                    timestamp = cmp.get('v.timestamp');
                    if (response.dto.timestamp && response.dto.timestamp == timestamp) {
                        cmp.set('v.meta', response);
                        var data = response.dto.tableData || [];

                        dataTableCmp.setAttr('v.columns', helper.getColumns(cmp, helper, response.dto.tableColumns));
                        dataTableCmp.setData(data.records);

                        helper.getBaseCmp(cmp).find('errorMessages').clearErrors();
                        cmp.set('v.hasMoreRecords', data.hasMore);
                        cmp.set('v.countRecords', data.count);

                        resolve(data);
                    }
                }, function (errors) {
                    helper.getBaseCmp(cmp).find('errorMessages').showErrors(errors, true);
                    reject(errors);
                }
            ).then(function () {
                dataTableCmp.set('v.showSpinner', false);
            });
        }));

    },

    getColumns: function (cmp, helper, columns) {

        var overrideColumns = cmp.get('v.overrideColumns');
        if (overrideColumns.length > 0) {
            overrideColumns.forEach(function (column) {
                switch (column.changeAction) {
                    case 'add':
                        columns.push(column);
                        break;
                    case 'delete':
                        if (column.position) {
                            columns.splice(column.position - 1, 1);
                        }
                        break;
                    case 'override':
                        if (column.position) {
                            _.extend(columns[column.position - 1], column);
                        }
                        break;
                    default:
                        break;
                }
            });
        }

        return columns;
    },

    onAfterSOQLDatatableLoadEventFire: function (cmp, event, helper) {
        var onAfterSOQLDatatableLoad = cmp.getEvent('onAfterSOQLDatatableLoad');
        onAfterSOQLDatatableLoad.setParams({
            'payload': {
                'isLoaded': true
            }
        });
        onAfterSOQLDatatableLoad.fire();
    },

    onAfterSOQLDatatableRefreshEventFire: function (cmp, event, helper) {
        var onAfterSOQLDatatableRefresh = cmp.getEvent('onAfterSOQLDatatableRefresh');
        onAfterSOQLDatatableRefresh.setParams({
            'payload': {
                'isLoaded': true
            }
        });
        onAfterSOQLDatatableRefresh.fire();
    }
})