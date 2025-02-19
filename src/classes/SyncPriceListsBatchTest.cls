@IsTest
private class SyncPriceListsBatchTest {

    @TestSetup
    static void setup() {
        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Standard to Maica';
        setting.Sync_Mode__c = 'Scheduled';
        upsert setting;

        Pricebook2 pbVar = new Pricebook2(
                Name = 'Test Pricebook2',
                IsActive = true
        );
        insert pbVar;
    }

    @IsTest
    static void testInsertBehaviour() {
        Response resp = new SyncPriceListsBatch().process(new Request());
        Assert.isTrue(resp.isValid);

        Test.startTest();
        Database.executeBatch(new SyncPriceListsBatch(true), 1);
        Test.stopTest();

        Pricebook2 pbVar = (Pricebook2) Utils.arrays.firstOrException([
                SELECT Id, Price_List__c, Name, IsActive
                FROM Pricebook2
        ], 'No Pricebook2.');

        List<maica_cc__Price_List__c> priceLists = [
                SELECT Id, Price_Book__c, Name, maica_cc__Active__c
                FROM maica_cc__Price_List__c
                WHERE Id IN (SELECT Price_List__c FROM Pricebook2 WHERE Id = :pbVar.Id)
                AND Price_Book__c = :pbVar.Id
        ];

        Assert.isTrue(!priceLists.isEmpty());
        Assert.isTrue(priceLists.size() == 1);
        maica_cc__Price_List__c priceListVar = priceLists[0];
        Assert.isTrue(pbVar.Id.equals(priceListVar.Price_Book__c));
        Assert.isTrue(priceListVar.Id.equals(pbVar.Price_List__c));
        Assert.isTrue(pbVar.Name.equals(priceListVar.Name));
        Assert.isTrue(priceListVar.maica_cc__Active__c == true && pbVar.IsActive.equals(priceListVar.maica_cc__Active__c));
    }

    @IsTest
    static void testUpdateBehaviour() {
        Pricebook2 pbVar = (Pricebook2) Utils.arrays.firstOrException([
                SELECT Id, Price_List__c, Name, IsActive
                FROM Pricebook2
        ], 'No Pricebook2.');
        pbVar.Name = 'Test Pricebook2 Test';
        update pbVar;

        Test.startTest();
        Database.executeBatch(new SyncPriceListsBatch(), 1);
        Test.stopTest();

        maica_cc__Price_List__c priceListVar = (maica_cc__Price_List__c) Utils.arrays.firstOrNull([
                SELECT Id, Name
                FROM maica_cc__Price_List__c
                WHERE Id IN (SELECT Price_List__c FROM Pricebook2 WHERE Id = :pbVar.Id)
                AND Price_Book__c = :pbVar.Id
        ]);

        Assert.isTrue('Test Pricebook2 Test'.equals(pbVar.Name) && pbVar.Name.equals(priceListVar.Name));
    }

    @IsTest
    static void testDelete() {
        Pricebook2 pbVar = (Pricebook2) Utils.arrays.firstOrException([
                SELECT Id, Price_List__c, Name, IsActive
                FROM Pricebook2
        ], 'No Pricebook2.');
        pbVar.Name = 'Test Pricebook2 Test';
        delete pbVar;

        Test.startTest();
        Database.executeBatch(new SyncPriceListsBatch(), 1);
        Test.stopTest();

        maica_cc__Price_List__c priceListVar = (maica_cc__Price_List__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Price_List__c
                WHERE Id IN (SELECT Price_List__c FROM Pricebook2 WHERE Id = :pbVar.Id)
                AND Price_Book__c = :pbVar.Id
        ]);
        Assert.isNull(priceListVar);
    }

    @IsTest
    static void testCatch() {
        SyncPriceListsBatch bc = new SyncPriceListsBatch();
        bc.execute(null, null);
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Details__c
                FROM maica_cc__Log__c
        ]);
        Assert.isNotNull(log);
        Assert.areEqual('Attempt to de-reference a null object', log.maica_cc__Details__c, 'Error message should be \'Attempt to de-reference a null object\'');
    }
}