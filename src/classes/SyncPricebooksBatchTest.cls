@IsTest
private class SyncPricebooksBatchTest {

    @TestSetup
    static void setup() {
        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Maica to Standard';
        setting.Sync_Mode__c = 'Scheduled';
        upsert setting;

        maica_cc__Price_List__c plVar = new maica_cc__Price_List__c(
                Name = 'Test Price List',
                maica_cc__Active__c = true
        );
        insert plVar;
    }

    @IsTest
    static void testInsertBehaviour() {
        Response resp = new SyncPricebooksBatch().process(new Request());
        Assert.isTrue(resp.isValid);

        Test.startTest();
        Database.executeBatch(new SyncPricebooksBatch(true), 1);
        Test.stopTest();

        maica_cc__Price_List__c plVar = (maica_cc__Price_List__c) Utils.arrays.firstOrException([
                SELECT Id, Price_Book__c, Name, maica_cc__Active__c
                FROM maica_cc__Price_List__c
        ], 'No maica_cc__Price_List__c');

        List<Pricebook2> pbs = [
                SELECT Id, Price_List__c, Name, IsActive
                FROM Pricebook2
                WHERE Id IN (SELECT Price_Book__c FROM maica_cc__Price_List__c WHERE Id = :plVar.Id)
                AND Price_List__c = :plVar.Id
        ];

        Assert.isTrue(!pbs.isEmpty());
        Assert.isTrue(pbs.size() == 1);
        Pricebook2 pbVar = pbs[0];
        Assert.isTrue(plVar.maica_cc__Active__c == true && plVar.maica_cc__Active__c.equals(pbVar.IsActive));
        Assert.isTrue(plVar.Id.equals(pbVar.Price_List__c));
        Assert.isTrue(pbVar.Id.equals(plVar.Price_Book__c));
        Assert.isTrue(plVar.Name.equals(pbVar.Name));
    }

    @IsTest
    static void testUpdateBehaviour() {
        maica_cc__Price_List__c plVar = (maica_cc__Price_List__c) Utils.arrays.firstOrException([
                SELECT Id, Price_Book__c, Name, maica_cc__Active__c
                FROM maica_cc__Price_List__c
        ], 'No maica_cc__Price_List__c');
        plVar.Name = 'Test Price List 1';
        update plVar;

        Test.startTest();
        Database.executeBatch(new SyncPricebooksBatch(), 1);
        Test.stopTest();
        
        Pricebook2 pbVar = (Pricebook2) Utils.arrays.firstOrNull([
                SELECT Id, Name
                FROM Pricebook2
                WHERE Id IN (SELECT Price_Book__c FROM maica_cc__Price_List__c WHERE Id = :plVar.Id)
                AND Price_List__c = :plVar.Id
        ]);
        Assert.isTrue('Test Price List 1'.equals(plVar.Name) && plVar.Name.equals(pbVar.Name));
    }

    @IsTest
    static void testDelete() {
        maica_cc__Price_List__c plVar = (maica_cc__Price_List__c) Utils.arrays.firstOrException([
                SELECT Id, Price_Book__c, Name, maica_cc__Active__c
                FROM maica_cc__Price_List__c
        ], 'No maica_cc__Price_List__c');
        delete plVar;

        Test.startTest();
        Database.executeBatch(new SyncPricebooksBatch(), 1);
        Test.stopTest();
        
        Pricebook2 pbVar = (Pricebook2) Utils.arrays.firstOrNull([
                SELECT Id
                FROM Pricebook2
                WHERE Id IN (SELECT Price_Book__c FROM maica_cc__Price_List__c WHERE Id = :plVar.Id)
                AND Price_List__c = :plVar.Id
        ]);
        Assert.isNull(pbVar);
    }

    @IsTest
    static void testCatch() {
        SyncPricebooksBatch bc = new SyncPricebooksBatch();
        bc.execute(null, null);
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Details__c
                FROM maica_cc__Log__c
        ]);
        Assert.isNotNull(log);
        Assert.areEqual('Attempt to de-reference a null object', log.maica_cc__Details__c, 'Error message should be \'Attempt to de-reference a null object\'');
    }
}