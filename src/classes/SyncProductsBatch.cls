public without sharing class SyncProductsBatch extends AbstractProcessor implements Database.Batchable<SObject>, Schedulable {

    private Boolean isScheduled = false;

    public SyncProductsBatch() {
    }

    public SyncProductsBatch(Boolean isScheduled) {
        this.isScheduled = isScheduled;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SyncProductsBatch(true), 100);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('' +
                'SELECT Id ' +
                'FROM maica_cc__Support_Item__c ' +
                '');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            fflib_QueryFactory queryFactory = new fflib_QueryFactory(maica_cc__Support_Item__c.SObjectType);
            queryFactory.selectFields(SyncObjectsProc.getAvailableFields(maica_cc__Support_Item__c.SObjectType).keySet());
            queryFactory.setCondition('Id IN :scope');
            List<maica_cc__Support_Item__c> records = Database.query(queryFactory.toSOQL());
            MDTM_SyncProducts.sync(records);
        } catch (Exception e) {
            maica_cc__Log__c logVar = new maica_cc__Log__c(
                    maica_cc__Details__c = e.getMessage(),
                    maica_cc__Job_Id__c = ('' + bc?.getJobId()).left(15),
                    maica_cc__Source__c = 'Sync Products Batch',
                    maica_cc__Type__c = 'Error',
                    maica_cc__Processor__c = 'SyncProductsBatch',
                    maica_cc__Payload__c = JSON.serialize(new Map<String, Object>{
                            'ids' => Utils.sObjects.getIdFieldValues(scope == null ? new List<SObject>() : scope, 'Id')
                    })
            );
            insert logVar;
        }
    }

    public void finish(Database.BatchableContext bc) {
        List<maica_cc__Log__c> errorLogs = [
                SELECT Id
                FROM maica_cc__Log__c
                WHERE maica_cc__Type__c = 'Error'
                AND maica_cc__Job_Id__c = :('' + bc?.getJobId()).left(15)
        ];

        if (errorLogs.isEmpty()) {
            delete [SELECT Id FROM Product2 WHERE Support_Item__c = NULL];
            if (this.isScheduled) {
                Database.executeBatch(new SyncPricebooksBatch(true), 100);
            }
        }
    }

    public override Response process(Request request) {
        this.request = request;

        String jobId = Database.executeBatch(this, 100);
        this.response.put('jobId', jobId);

        return this.response;
    }
}