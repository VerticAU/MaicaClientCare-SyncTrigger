public without sharing class SyncPricebookEntriesBatch extends AbstractProcessor implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('' +
                'SELECT Id, Price_Book_Entry__c ' +
                'FROM maica_cc__Price_List_Entry__c ' +
                'WHERE maica_cc__Price_List__r.Price_Book__c != NULL ' +
                'AND maica_cc__Support_Item__r.Product__c != NULL ' +
                '');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            MDTM_SyncPricebookEntries.sync(scope);
        } catch (Exception e) {
            maica_cc__Log__c logVar = new maica_cc__Log__c(
                    maica_cc__Details__c = e.getMessage(),
                    maica_cc__Job_Id__c = ('' + bc?.getJobId()).left(15),
                    maica_cc__Source__c = 'Sync Pricebook Entries Batch',
                    maica_cc__Type__c = 'Error',
                    maica_cc__Processor__c = 'SyncPricebookEntriesBatch',
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
            delete [SELECT Id FROM PricebookEntry WHERE Price_List_Entry__c = NULL AND Pricebook2.IsStandard = FALSE];
        }
    }

    public override Response process(Request request) {
        this.request = request;

        String jobId = Database.executeBatch(this, 100);
        this.response.put('jobId', jobId);

        return this.response;
    }
}