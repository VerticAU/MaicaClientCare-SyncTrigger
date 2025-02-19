@IsTest
private class SyncPricebookEntriesBatchTest {

    @TestSetup
    static void setup() {
        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Maica to Standard';
        setting.Sync_Mode__c = 'Scheduled';
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

        new SyncProductsBatch().execute(null, new List<SObject>{supportItemVar});

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

        new SyncPricebooksBatch().execute(null, new List<SObject>{plVar});

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
    }

    @IsTest
    static void testInsertBehaviour() {
        Response resp = new SyncPricebookEntriesBatch().process(new Request());
        Assert.isTrue(resp.isValid);

        Test.startTest();
        Database.executeBatch(new SyncPricebookEntriesBatch(), 1);
        Test.stopTest();

        maica_cc__Price_List_Entry__c pleVar = (maica_cc__Price_List_Entry__c) Utils.arrays.firstOrException([
                SELECT Id, Price_Book_Entry__c, maica_cc__Support_Item__c, maica_cc__Active__c,
                        maica_cc__Unit_Price__c, maica_cc__Support_Item__r.Product__c,maica_cc__Price_List__r.Price_Book__c
                FROM maica_cc__Price_List_Entry__c
        ], 'No maica_cc__Price_List_Entry__c.');

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
    }

    @IsTest
    static void testUpdateBehaviour() {
        maica_cc__Price_List_Entry__c pleVar = (maica_cc__Price_List_Entry__c) Utils.arrays.firstOrException([
                SELECT Id, Price_Book_Entry__c, maica_cc__Support_Item__c, maica_cc__Active__c,
                        maica_cc__Unit_Price__c, maica_cc__Support_Item__r.Product__c,maica_cc__Price_List__r.Price_Book__c
                FROM maica_cc__Price_List_Entry__c
        ], 'No maica_cc__Price_List_Entry__c.');
        pleVar.maica_cc__Unit_Price__c = 12;
        update pleVar;

        Test.startTest();
        Database.executeBatch(new SyncPricebookEntriesBatch(), 1);
        Test.stopTest();

        PricebookEntry pbeVar = (PricebookEntry) Utils.arrays.firstOrNull([
                SELECT Id, UnitPrice
                FROM PricebookEntry
                WHERE Price_List_Entry__c = :pleVar.Id
        ]);
        List<PricebookEntry> entries = [
                SELECT Id
                FROM PricebookEntry
                WHERE Pricebook2Id != :Test.getStandardPricebookId()
        ];
        List<PricebookEntry> standardPricebookEntries = [
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
    }

    @IsTest
    static void testDelete() {
        maica_cc__Price_List_Entry__c pleVar = (maica_cc__Price_List_Entry__c) Utils.arrays.firstOrException([
                SELECT Id, Price_Book_Entry__c, maica_cc__Support_Item__c, maica_cc__Active__c,
                        maica_cc__Unit_Price__c, maica_cc__Support_Item__r.Product__c,maica_cc__Price_List__r.Price_Book__c
                FROM maica_cc__Price_List_Entry__c
        ], 'No maica_cc__Price_List_Entry__c.');
        delete pleVar;

        Test.startTest();
        Database.executeBatch(new SyncPricebookEntriesBatch(), 1);
        Test.stopTest();

        PricebookEntry pbeVar = (PricebookEntry) Utils.arrays.firstOrNull([
                SELECT Id, UnitPrice
                FROM PricebookEntry
                WHERE Price_List_Entry__c = :pleVar.Id
        ]);
        Assert.isNull(pbeVar);
    }

    @IsTest
    static void testCatch() {
        SyncPricebookEntriesBatch bc = new SyncPricebookEntriesBatch();
        bc.execute(null, null);
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Details__c
                FROM maica_cc__Log__c
        ]);
        Assert.isNotNull(log);
        Assert.areEqual('Attempt to de-reference a null object', log.maica_cc__Details__c, 'Error message should be \'Attempt to de-reference a null object\'');
    }
}