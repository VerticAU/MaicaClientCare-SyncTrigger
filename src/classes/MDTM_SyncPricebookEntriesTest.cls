@IsTest
private class MDTM_SyncPricebookEntriesTest {

    @IsTest
    static void testBehaviour() {
        setupTestHandlers();

        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Maica to Standard';
        setting.Sync_Mode__c = 'Triggered';
        upsert setting;

        maica_cc__Support_Category__c supportCategory = new maica_cc__Support_Category__c(
                Name = 'Test Support Category'
        );
        insert supportCategory;

        maica_cc__Support_Item__c supportItemVar = new maica_cc__Support_Item__c(
                Name = 'Test Product',
                maica_cc__Support_Category__c = supportCategory.Id,
                maica_cc__Service_Day__c = 'Anytime',
                maica_cc__Service_Time__c = 'Anytime'
        );
        insert supportItemVar;

        List<Product2> products = [
                SELECT Id, Support_Item__c
                FROM Product2
                WHERE Support_Item__c = :supportItemVar.Id
        ];
        Assert.isTrue(!products.isEmpty());
        Assert.isTrue(products.size() == 1);

        maica_cc__Price_List__c plVar = new maica_cc__Price_List__c(
                Name = 'Test Price List'
        );
        insert plVar;

        List<Pricebook2> pricebook2s = [
                SELECT Id, Price_List__c
                FROM Pricebook2
                WHERE Price_List__c = :plVar.Id
        ];
        Assert.isTrue(!pricebook2s.isEmpty());
        Assert.isTrue(pricebook2s.size() == 1);

        maica_cc__Price_List_Entry__c pleVar = new maica_cc__Price_List_Entry__c(
                maica_cc__Support_Item__c = supportItemVar.Id,
                maica_cc__Price_List__c = plVar.Id,
                maica_cc__Active__c = true,
                maica_cc__Unit_Price__c = 10
        );
        insert pleVar;

        pleVar = (maica_cc__Price_List_Entry__c) Utils.arrays.firstOrException([
                SELECT Id, Price_Book_Entry__c, maica_cc__Support_Item__c, maica_cc__Active__c,
                        maica_cc__Unit_Price__c, maica_cc__Support_Item__r.Product__c,maica_cc__Price_List__r.Price_Book__c
                FROM maica_cc__Price_List_Entry__c
                WHERE Id = :pleVar.Id
        ], 'No maica_cc__Price_List__c with Id: ' + plVar.Id);

        PricebookEntry pbeVar = (PricebookEntry) Utils.arrays.firstOrNull([
                SELECT Id, UnitPrice, IsActive, Product2Id, Pricebook2Id, Price_List_Entry__c
                FROM PricebookEntry
                WHERE Price_List_Entry__c = :pleVar.Id
        ]);

        List<PricebookEntry> entries = [
                SELECT Id
                FROM PricebookEntry
                WHERE Pricebook2Id != :Test.getStandardPricebookId()
        ];
        Assert.isTrue(!entries.isEmpty());
        Assert.isTrue(entries.size() == 1);

        List<PricebookEntry> standardPricebookEntries = [
                SELECT Id, UnitPrice, IsActive, Product2Id
                FROM PricebookEntry
                WHERE Product2Id  = :pleVar.maica_cc__Support_Item__r.Product__c
                AND Pricebook2Id = :Test.getStandardPricebookId()
        ];

        Assert.isTrue(!standardPricebookEntries.isEmpty());
        Assert.isTrue(standardPricebookEntries.size() == 1);
        Assert.isTrue(pbeVar != null);
        Assert.isTrue(pleVar.Id.equals(pbeVar.Price_List_Entry__c));
        Assert.isTrue(pbeVar.Id.equals(pleVar.Price_Book_Entry__c));
        Assert.isTrue(pbeVar.IsActive == true && pleVar.maica_cc__Active__c.equals(pbeVar.IsActive));
        Assert.isTrue(pbeVar.UnitPrice == pleVar.maica_cc__Unit_Price__c);
        Assert.isTrue(pbeVar.Product2Id.equals(pleVar.maica_cc__Support_Item__r?.Product__c));
        Assert.isTrue(pbeVar.Pricebook2Id.equals(pleVar.maica_cc__Price_List__r?.Price_Book__c));

        pleVar.maica_cc__Unit_Price__c = 11;
        update pleVar;

        pbeVar = (PricebookEntry) Utils.arrays.firstOrNull([
                SELECT Id, UnitPrice
                FROM PricebookEntry
                WHERE Price_List_Entry__c = :pleVar.Id
        ]);

        Assert.isTrue(pleVar.maica_cc__Unit_Price__c == pbeVar.UnitPrice);

        delete [SELECT Id FROM PricebookEntry WHERE Pricebook2Id != :Test.getStandardPricebookId()];
        pleVar.maica_cc__Unit_Price__c = 12;
        update pleVar;

        pbeVar = (PricebookEntry) Utils.arrays.firstOrNull([
                SELECT Id, UnitPrice
                FROM PricebookEntry
                WHERE Price_List_Entry__c = :pleVar.Id
        ]);
        entries = [
                SELECT Id
                FROM PricebookEntry
                WHERE Pricebook2Id != :Test.getStandardPricebookId()
        ];
        standardPricebookEntries = [
                SELECT Id, UnitPrice, IsActive, Product2Id
                FROM PricebookEntry
                WHERE Product2Id  = :pleVar.maica_cc__Support_Item__r.Product__c
                AND Pricebook2Id = :Test.getStandardPricebookId()
        ];

        Assert.isTrue(pbeVar != null);
        Assert.isTrue(!entries.isEmpty());
        Assert.isTrue(entries.size() == 1);
        Assert.isTrue(pleVar.maica_cc__Unit_Price__c == pbeVar.UnitPrice);
        Assert.isTrue(!standardPricebookEntries.isEmpty());
        Assert.isTrue(standardPricebookEntries.size() == 1);

        delete pleVar;
        pbeVar = (PricebookEntry) Utils.arrays.firstOrNull([
                SELECT Id
                FROM PricebookEntry
                WHERE Price_List_Entry__c = :pleVar.Id
        ]);
        Assert.isNull(pbeVar);
    }

    static void setupTestHandlers() {
        maica_cc.MDTM.setupTestHandlers(new List<maica_cc__Trigger_Handler__mdt>{
                new maica_cc__Trigger_Handler__mdt(
                        maica_cc__Object__c = '' + maica_cc__Price_List__c.SObjectType,
                        maica_cc__Class__c = '' + MDTM_SyncPricebooks.class,
                        maica_cc__Active__c = true
                ),
                new maica_cc__Trigger_Handler__mdt(
                        maica_cc__Object__c = '' + maica_cc__Support_Item__c.SObjectType,
                        maica_cc__Class__c = '' + MDTM_SyncProducts.class,
                        maica_cc__Active__c = true
                ),
                new maica_cc__Trigger_Handler__mdt(
                        maica_cc__Object__c = '' + maica_cc__Price_List_Entry__c.SObjectType,
                        maica_cc__Class__c = '' + MDTM_SyncPricebookEntries.class,
                        maica_cc__Active__c = true
                )
        });
    }
}