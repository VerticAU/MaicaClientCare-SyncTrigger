({
    updateStatus: function (cmp, event, helper) {
        var jobId = cmp.get('v.jobId');
        var that = this;

        helper.execute(
            cmp,
            'SOQLProc',
            {
                SOQL: 'SELECT  Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors, CompletedDate, MethodName, ExtendedStatus, ParentJobId, LastProcessed, LastProcessedOffset ' +
                    'FROM AsyncApexJob ' +
                    'WHERE Id = \'' + jobId + '\''
            },
            function (response) {

                if (!response.dto.records.length) {
                    cmp.set('v.meta.error', 'No Async Job with Id: ' + jobId);
                    cmp.set('v.stage', 'failure');
                    helper.clearInterval(cmp);
                    var completeEvent = cmp.getEvent("onComplete");
                    completeEvent.setParams({
                        payload: {
                            success: false,
                            error: 'No Async Job with Id: ' + jobId
                        }
                    });
                    completeEvent.fire();
                    return;
                }

                var job = response.dto.records[0];
                cmp.set('v.job', job);

                var status = job.Status;
                var progress = Math.ceil((job.JobItemsProcessed || 0) / (job.TotalJobItems || 1) * 100);

                cmp.set('v.progress', progress);
                cmp.set('v.isShowProgress', job.Status === 'Processing' || progress > 0);

                console.log('progress', progress);

                if (status == 'Completed') {
                    if(job.ExtendedStatus){
                        cmp.set('v.meta.error', job.ExtendedStatus);
                        cmp.set('v.stage', 'failure');
                        helper.clearInterval(cmp);
                        var completeEvent = cmp.getEvent("onComplete");
                        completeEvent.setParams({
                            payload: {
                                success: false,
                                error: job.ExtendedStatus
                            }
                        });
                        completeEvent.fire();
                    } else {
                        cmp.set('v.meta.error', null);
                        cmp.set('v.stage', 'success');
                        cmp.set('v.progress', 100);
                        helper.clearInterval(cmp);
                        var completeEvent = cmp.getEvent("onComplete");
                        completeEvent.setParams({"payload": {success: true, isAnyFailed: (cmp.get('v.totalErrors') || 0) > 0}});
                        completeEvent.fire();
                    }
                } else if (status == 'Aborted') {
                    cmp.set('v.meta.error', 'The Job has Aborted. Job Id: ' + jobId);
                    cmp.set('v.stage', 'failure');
                    helper.clearInterval(cmp);
                    var completeEvent = cmp.getEvent("onComplete");
                    completeEvent.setParams({
                        payload: {
                            success: false,
                            error: 'The Job has Aborted'
                        }
                    });
                    completeEvent.fire();
                } else if (status == 'Failed') {
                    cmp.set('v.meta.error', job.ExtendedStatus);
                    cmp.set('v.stage', 'failure');
                    helper.clearInterval(cmp);
                    var completeEvent = cmp.getEvent("onComplete");
                    completeEvent.setParams({
                        payload: {
                            success: false,
                            error: job.ExtendedStatus
                        }
                    });
                    completeEvent.fire();
                } else {
                    if (!cmp.get('v.interval')) {
                        var interval = window.setInterval(
                            $A.getCallback(function () {

                                that.updateStatus(cmp, event, helper);

                            }),
                            1000
                        );
                        cmp.set('v.interval', interval);
                    }
                }

            }
        );

    },

    clearInterval: function (cmp) {
        var interval = cmp.get('v.interval');
        if (interval) {
            clearInterval(interval);
            cmp.set('v.interval', null);
        }
    },

    initColumns: function(cmp) {
        var columns = [];

        columns.push({
            changeAction: 'add',
            type: 'button-icon',
            sortable: false,
            initialWidth: 40,
            typeAttributes: {
                title: 'Open Log',
                name: 'open',
                iconName: 'utility:new_window',
                doAction: function (row) {
                    window.open('/' + row.id, '_blank');
                }
            }
        });

        cmp.set('v.overrideColumns', columns);
    },

})