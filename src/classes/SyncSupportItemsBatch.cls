public without sharing class SyncSupportItemsBatch extends AbstractProcessor implements Database.Batchable<SObject>, Schedulable {

    private Boolean isScheduled = false;

    public SyncSupportItemsBatch() {
    }

    public SyncSupportItemsBatch(Boolean isScheduled) {
        this.isScheduled = isScheduled;
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new SyncSupportItemsBatch(true), 100);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('' +
                'SELECT Id ' +
                'FROM Product2 ' +
                '');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            fflib_QueryFactory queryFactory = new fflib_QueryFactory(Product2.SObjectType);
            queryFactory.selectFields(SyncObjectsProc.getAvailableFields(Product2.SObjectType).keySet());
            queryFactory.setCondition('Id IN :scope');
            List<Product2> records = Database.query(queryFactory.toSOQL());
            MDTM_SyncSupportItems.sync(records);
        } catch (Exception e) {
            maica_cc__Log__c logVar = new maica_cc__Log__c(
                    maica_cc__Details__c = e.getMessage(),
                    maica_cc__Job_Id__c = ('' + bc?.getJobId()).left(15),
                    maica_cc__Source__c = 'Sync Support Items Batch',
                    maica_cc__Type__c = 'Error',
                    maica_cc__Processor__c = 'SyncSupportItemsBatch',
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
            delete [SELECT Id FROM maica_cc__Support_Item__c WHERE Product__c = NULL];
            if (this.isScheduled) {
                Database.executeBatch(new SyncPriceListsBatch(true), 100);
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