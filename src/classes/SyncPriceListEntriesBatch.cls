public without sharing class SyncPriceListEntriesBatch extends AbstractProcessor implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('' +
                'SELECT Id ' +
                'FROM PricebookEntry ' +
                'WHERE Pricebook2.Price_List__c != NULL ' +
                'AND Product2.Support_Item__c != NULL ' +
                'AND Pricebook2.IsStandard = FALSE ' +
                '');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            fflib_QueryFactory queryFactory = new fflib_QueryFactory(PricebookEntry.SObjectType);
            queryFactory.selectFields(SyncObjectsProc.getAvailableFields(PricebookEntry.SObjectType).keySet());
            queryFactory.selectField('Pricebook2.Price_List__c');
            queryFactory.selectField('Product2.Support_Item__c');
            queryFactory.setCondition('Id IN :scope AND Pricebook2.Price_List__c != NULL AND Product2.Support_Item__c != NULL');
            List<PricebookEntry> records = Database.query(queryFactory.toSOQL());

            Set<Id> supportItemIds = new Set<Id>();
            Set<Id> priceListIds = new Set<Id>();
            for (PricebookEntry entry : records) {
                supportItemIds.add(entry.Product2.Support_Item__c);
                priceListIds.add(entry.Pricebook2.Price_List__c);
            }
            List<maica_cc__Price_List__c> priceLists = [
                    SELECT Id, Price_Book__c
                    FROM maica_cc__Price_List__c
                    WHERE Id IN :priceListIds
            ];
            Map<String, SObject> priceListsByPricebook = Utils.sObjects.getSObjectsByAnyFieldMap(priceLists, maica_cc__Price_List__c.Price_Book__c);
            List<maica_cc__Support_Item__c> supportItems = [
                    SELECT Id, Product__c
                    FROM maica_cc__Support_Item__c
                    WHERE Id IN :supportItemIds
            ];
            Map<String, SObject> supportItemsByProduct = Utils.sObjects.getSObjectsByAnyFieldMap(supportItems, maica_cc__Support_Item__c.Product__c);

            //need to create bindRecordsMap to bind PricebookEntry with custom fields like Support_Item__c, Price_List__c
            //to then think them to Price_List_Entry__c
            Map<String, Map<String, Object>> bindRecordsMap = new Map<String, Map<String, Object>>();
            for (Map<String, Object> recordMap : new AutoMapper().getSObjectsAsMaps(records)) {
                Map<String, Object> bindRecordMap = new Map<String, Object>();
                bindRecordMap.put('maica_cc__Price_List__c', priceListsByPricebook.get((String) recordMap.get('Pricebook2Id'))?.Id);
                bindRecordMap.put('maica_cc__Support_Item__c', supportItemsByProduct.get((String) recordMap.get('Product2Id'))?.Id);
                bindRecordsMap.put((String) recordMap.get('Id'), bindRecordMap);
            }

            new SyncObjectsProc().process(new Map<String, Object>{
                    'sObjectType1' => 'PricebookEntry',
                    'relationshipFieldToObj2Str' => 'Price_List_Entry__c',
                    'sObjectType2' => 'maica_cc__Price_List_Entry__c',
                    'relationshipFieldToObj1Str' => 'Price_Book_Entry__c',
                    'obj1Records' => new AutoMapper().getSObjectsAsMaps(records),
                    'bindObj1RecordsMap' => bindRecordsMap,
                    'isDelete' => false,
                    'isCustomToStandard' => false,
                    'differentFieldsMap' => new Map<String, Object>{
                            'maica_cc__Active__c' => 'IsActive',
                            'maica_cc__Support_Item__c' => 'Product2Id',
                            'maica_cc__Price_List__c' => 'Pricebook2Id'
                    }
            });
        } catch (Exception e) {
            maica_cc__Log__c logVar = new maica_cc__Log__c(
                    maica_cc__Details__c = e.getMessage(),
                    maica_cc__Job_Id__c = ('' + bc?.getJobId()).left(15),
                    maica_cc__Source__c = 'Sync Price List EntriesBatch',
                    maica_cc__Type__c = 'Error',
                    maica_cc__Processor__c = 'SyncPriceListEntriesBatch',
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
            delete [SELECT Id FROM maica_cc__Price_List_Entry__c WHERE Price_Book_Entry__c = NULL];
        }
    }

    public override Response process(Request request) {
        this.request = request;

        String jobId = Database.executeBatch(this, 1);
        this.response.put('jobId', jobId);

        return this.response;
    }
}