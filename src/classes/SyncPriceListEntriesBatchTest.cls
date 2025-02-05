@IsTest
private class SyncPriceListEntriesBatchTest {

    @TestSetup
    static void setup() {
        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Standard to Maica';
        setting.Sync_Mode__c = 'Scheduled';
        upsert setting;

        maica_cc__Support_Category__c supportCategory = new maica_cc__Support_Category__c(
                Name = 'Test Support Category'
        );
        insert supportCategory;

        Product2 product2Var = new Product2(
                Name = 'Test Product',
                Support_Category__c = supportCategory.Id,
                Service_Day__c = 'Anytime',
                Service_Time__c = 'Anytime'
        );
        insert product2Var;

        new SyncSupportItemsBatch().execute(null, new List<SObject>{
                product2Var
        });

        List<maica_cc__Support_Item__c> supportItems = [
                SELECT Id, Product__c
                FROM maica_cc__Support_Item__c
                WHERE Product__c = :product2Var.Id
        ];
        Assert.isTrue(!supportItems.isEmpty());
        Assert.isTrue(supportItems.size() == 1);

        Pricebook2 pbVar = new Pricebook2(
                Name = 'Test Price List'
        );
        insert pbVar;

        new SyncPriceListsBatch().execute(null, new List<SObject>{
                pbVar
        });

        List<maica_cc__Price_List__c> priceLists = [
                SELECT Id, Price_Book__c
                FROM maica_cc__Price_List__c
                WHERE Price_Book__c = :pbVar.Id
        ];
        Assert.isTrue(!priceLists.isEmpty());
        Assert.isTrue(priceLists.size() == 1);

        PricebookEntry standardPbeVar = new PricebookEntry(
                Product2Id = product2Var.Id,
                Pricebook2Id = Test.getStandardPricebookId(),
                IsActive = true,
                UnitPrice = 10
        );
        insert standardPbeVar;

        PricebookEntry pbeVar = new PricebookEntry(
                Product2Id = product2Var.Id,
                Pricebook2Id = pbVar.Id,
                IsActive = true,
                UnitPrice = 10
        );
        insert pbeVar;
    }

    @IsTest
    static void testInsertBehaviour() {
        Response resp = new SyncPriceListEntriesBatch().process(new Request());
        Assert.isTrue(resp.isValid);

        Test.startTest();
        Database.executeBatch(new SyncPriceListEntriesBatch(), 100);
        Test.stopTest();

        PricebookEntry pbeVar = (PricebookEntry) Utils.arrays.firstOrException([
                SELECT Id, Price_List_Entry__c, Product2Id, IsActive,
                        UnitPrice, Product2.Support_Item__c, Pricebook2.Price_List__c
                FROM PricebookEntry
                WHERE Pricebook2Id != :Test.getStandardPricebookId()
        ], 'No PricebookEntry.');

        maica_cc__Price_List_Entry__c pleVar = (maica_cc__Price_List_Entry__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Unit_Price__c, maica_cc__Active__c, maica_cc__Support_Item__c, maica_cc__Price_List__c, Price_Book_Entry__c
                FROM maica_cc__Price_List_Entry__c
                WHERE Price_Book_Entry__c = :pbeVar.Id
        ]);

        List<maica_cc__Price_List_Entry__c> entries = [
                SELECT Id, Price_Book_Entry__c
                FROM maica_cc__Price_List_Entry__c
        ];
        Assert.isTrue(!entries.isEmpty());
        Assert.isTrue(entries.size() == 1);
        Assert.isTrue(pleVar != null);
        Assert.isTrue(pbeVar.Id.equals(pleVar.Price_Book_Entry__c));
        Assert.isTrue(pleVar.Id.equals(pbeVar.Price_List_Entry__c));
        Assert.isTrue(pleVar.maica_cc__Active__c == true && pbeVar.IsActive.equals(pleVar.maica_cc__Active__c));
        Assert.isTrue(pleVar.maica_cc__Unit_Price__c == pbeVar.UnitPrice);
        Assert.isTrue(pleVar.maica_cc__Support_Item__c.equals(pbeVar.Product2?.Support_Item__c));
        Assert.isTrue(pleVar.maica_cc__Price_List__c.equals(pbeVar.Pricebook2?.Price_List__c));
    }

    @IsTest
    static void testUpdateBehaviour() {
        PricebookEntry pbeVar = (PricebookEntry) Utils.arrays.firstOrException([
                SELECT Id, Price_List_Entry__c, Product2Id, IsActive,
                        UnitPrice, Product2.Support_Item__c, Pricebook2.Price_List__c
                FROM PricebookEntry
                WHERE Pricebook2Id != :Test.getStandardPricebookId()
        ], 'No PricebookEntry.');
        pbeVar.UnitPrice = 12;
        update pbeVar;

        Test.startTest();
        Database.executeBatch(new SyncPriceListEntriesBatch(), 100);
        Test.stopTest();

        maica_cc__Price_List_Entry__c pleVar = (maica_cc__Price_List_Entry__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Unit_Price__c
                FROM maica_cc__Price_List_Entry__c
                WHERE Price_Book_Entry__c = :pbeVar.Id
        ]);
        List<PricebookEntry> entries = [
                SELECT Id
                FROM PricebookEntry
                WHERE Pricebook2Id != :Test.getStandardPricebookId()
        ];

        Assert.isTrue(pbeVar != null);
        Assert.isTrue(!entries.isEmpty());
        Assert.isTrue(entries.size() == 1);
        Assert.isTrue(pleVar.maica_cc__Unit_Price__c == pbeVar.UnitPrice);
    }

    @IsTest
    static void testDelete() {
        PricebookEntry pbeVar = (PricebookEntry) Utils.arrays.firstOrException([
                SELECT Id, Price_List_Entry__c, Product2Id, IsActive,
                        UnitPrice, Product2.Support_Item__c, Pricebook2.Price_List__c
                FROM PricebookEntry
                WHERE Pricebook2Id != :Test.getStandardPricebookId()
        ], 'No PricebookEntry.');
        delete pbeVar;

        Test.startTest();
        Database.executeBatch(new SyncPriceListEntriesBatch(), 100);
        Test.stopTest();

        maica_cc__Price_List_Entry__c pleVar = (maica_cc__Price_List_Entry__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Unit_Price__c
                FROM maica_cc__Price_List_Entry__c
                WHERE Price_Book_Entry__c = :pbeVar.Id
        ]);
        Assert.isNull(pleVar);
    }

    @IsTest
    static void testCatch() {
        SyncPriceListEntriesBatch bc = new SyncPriceListEntriesBatch();
        bc.execute(null, null);
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Details__c
                FROM maica_cc__Log__c
        ]);
        Assert.isNotNull(log);
        Assert.areEqual('Attempt to de-reference a null object', log.maica_cc__Details__c, 'Error message should be \'Attempt to de-reference a null object\'');
    }
}