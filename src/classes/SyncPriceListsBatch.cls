public without sharing class SyncPriceListsBatch extends AbstractProcessor implements Database.Batchable<SObject> {

    private Boolean isScheduled = false;

    public SyncPriceListsBatch() {
    }

    public SyncPriceListsBatch(Boolean isScheduled) {
        this.isScheduled = isScheduled;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('' +
                'SELECT Id ' +
                'FROM Pricebook2 ' +
                'WHERE IsStandard = FALSE ' +
                '');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            fflib_QueryFactory queryFactory = new fflib_QueryFactory(Pricebook2.SObjectType);
            queryFactory.selectFields(SyncObjectsProc.getAvailableFields(Pricebook2.SObjectType).keySet());
            queryFactory.setCondition('Id IN :scope');
            List<Pricebook2> records = Database.query(queryFactory.toSOQL());
            MDTM_SyncPriceLists.sync(records);
        } catch (Exception e) {
            maica_cc__Log__c logVar = new maica_cc__Log__c(
                    maica_cc__Details__c = e.getMessage(),
                    maica_cc__Job_Id__c = ('' + bc?.getJobId()).left(15),
                    maica_cc__Source__c = 'Sync Price Lists Batch',
                    maica_cc__Type__c = 'Error',
                    maica_cc__Processor__c = 'SyncPriceListsBatch',
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
            delete [SELECT Id FROM maica_cc__Price_List__c WHERE Price_Book__c = NULL];
            if (this.isScheduled) {
                Database.executeBatch(new SyncPriceListEntriesBatch(), 1);
            }
        }
    }

    public override Response process(Request request) {
        this.request = request;

        String jobId = Database.executeBatch(this, 1);
        this.response.put('jobId', jobId);

        return this.response;
    }
}