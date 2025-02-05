global without sharing class MDTM_SyncPricebookEntries extends maica_cc.MDTM.Handler implements maica_cc.MDTM.AfterInsert, maica_cc.MDTM.AfterUpdate, maica_cc.MDTM.AfterDelete {

    public void onAfterInsert(List<SObject> records) {
        if ('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Maica to Standard'.equals(MaicaSetting.sync?.Sync_Direction__c)) {
            sync(records);
        }
    }

    public void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecordsMap) {
        if ('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Maica to Standard'.equals(MaicaSetting.sync?.Sync_Direction__c)) {
            sync(records);
        }
    }

    public void onAfterDelete(List<SObject> records) {
        if ('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Maica to Standard'.equals(MaicaSetting.sync?.Sync_Direction__c)) {
            sync(records);
        }
    }

    public static void sync(List<maica_cc__Price_List_Entry__c> records) {
        fflib_QueryFactory queryFactory = new fflib_QueryFactory(maica_cc__Price_List_Entry__c.SObjectType);
        queryFactory.selectFields(SyncObjectsProc.getAvailableFields(maica_cc__Price_List_Entry__c.SObjectType).keySet());
        queryFactory.selectField('maica_cc__Price_List__r.Price_Book__c');
        queryFactory.selectField('maica_cc__Support_Item__r.Product__c');
        queryFactory.setCondition('Id IN :records AND maica_cc__Price_List__r.Price_Book__c != NULL AND maica_cc__Support_Item__r.Product__c != NULL');
        records = Database.query(queryFactory.toSOQL());

        Set<Id> productIds = new Set<Id>();
        Set<Id> pricebookIds = new Set<Id>();
        for (maica_cc__Price_List_Entry__c plEntry : records) {
            productIds.add(plEntry.maica_cc__Support_Item__r.Product__c);
            pricebookIds.add(plEntry.maica_cc__Price_List__r.Price_Book__c);
        }
        List<Pricebook2> pricebook2s = [
                SELECT Id, Price_List__c
                FROM Pricebook2
                WHERE Id IN :pricebookIds
        ];
        Map<String, SObject> pricebook2sByPriceList = Utils.sObjects.getSObjectsByAnyFieldMap(pricebook2s, Pricebook2.Price_List__c);
        List<Product2> products = [
                SELECT Id, Support_Item__c
                FROM Product2
                WHERE Id IN :productIds
        ];
        Map<String, SObject> productsBySupportItem = Utils.sObjects.getSObjectsByAnyFieldMap(products, Product2.Support_Item__c);

        //need to create bindRecordsMap to bind Price_List_EntrY__c with standard fields like Product2Id, Pricebook2Id
        // to then think them to PricebookEntry
        Map<String, Map<String, Object>> bindRecordsMap = new Map<String, Map<String, Object>>();
        for (Map<String, Object> recordMap : new AutoMapper().getSObjectsAsMaps(records)) {
            Map<String, Object> bindRecordMap = new Map<String, Object>();
            bindRecordMap.put('Product2Id', productsBySupportItem.get((String) recordMap.get('maica_cc__Support_Item__c')).Id);
            bindRecordMap.put('Pricebook2Id', pricebook2sByPriceList.get((String) recordMap.get('maica_cc__Price_List__c')).Id);
            bindRecordsMap.put((String) recordMap.get('Id'), bindRecordMap);
        }

        //Create standard pricebook entries if they do not exist

        Pricebook2 standardPricebook2 = new Pricebook2();
        List<PricebookEntry> standardPricebookEntries = new List<PricebookEntry>();
        if (!Test.isRunningTest()) {
            standardPricebook2 = (Pricebook2) Utils.arrays.firstOrException([
                    SELECT Id
                    FROM Pricebook2
                    WHERE IsStandard = TRUE
            ], 'No Standard Pricebook2');

            standardPricebookEntries = [
                    SELECT Id, UnitPrice, IsActive, Product2Id
                    FROM PricebookEntry
                    WHERE Product2Id IN :productIds
                    AND Pricebook2.IsStandard = TRUE
            ];
        } else {
            standardPricebookEntries = [
                    SELECT Id, UnitPrice, IsActive, Product2Id
                    FROM PricebookEntry
                    WHERE Product2Id IN :productIds
                    AND Pricebook2Id = :Test.getStandardPricebookId()
            ];
        }
        Map<String, SObject> standardPricebookEntriesByProduct = Utils.sObjects.getSObjectsByAnyFieldMap(standardPricebookEntries, 'Product2Id');
        List<PricebookEntry> newPricebookEntries = new List<PricebookEntry>();

        for (maica_cc__Price_List_Entry__c entry : records) {
            String productId = productsBySupportItem.get((String) entry.maica_cc__Support_Item__c).Id;
            PricebookEntry standardPricebookEntry = (PricebookEntry) standardPricebookEntriesByProduct.get(productId);
            if (standardPricebookEntry == null) {
                PricebookEntry newPricebookEntry = new PricebookEntry(
                        Pricebook2Id = Test.isRunningTest() ? Test.getStandardPricebookId() : standardPricebook2.Id,
                        Product2Id = productId,
                        UnitPrice = (Decimal) entry.maica_cc__Unit_Price__c,
                        IsActive = (Boolean) entry.maica_cc__Active__c
                );
                System.debug(newPricebookEntry);
                newPricebookEntries.add(newPricebookEntry);
            }
        }
        System.debug(newPricebookEntries);
        if (!newPricebookEntries.isEmpty()) {
            insert newPricebookEntries;
        }

        new SyncObjectsProc().process(new Map<String, Object>{
                'sObjectType1' => 'maica_cc__Price_List_Entry__c',
                'relationshipFieldToObj2Str' => 'Price_Book_Entry__c',
                'sObjectType2' => 'PricebookEntry',
                'relationshipFieldToObj1Str' => 'Price_List_Entry__c',
                'obj1Records' => new AutoMapper().getSObjectsAsMaps(records),
                'bindObj1RecordsMap' => bindRecordsMap,
                'isDelete' => Trigger.isDelete == true,
                'isCustomToStandard' => true,
                'differentFieldsMap' => new Map<String, Object>{
                        'maica_cc__Active__c' => 'IsActive',
                        'maica_cc__Support_Item__c' => 'Product2Id',
                        'maica_cc__Price_List__c' => 'Pricebook2Id'
                }
        });
    }
}