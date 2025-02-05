@IsTest
private class SyncProductsBatchTest {

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
                maica_cc__Service_Time__c = 'Anytime',
                maica_cc__Quantity_Unit_Of_Measure__c = 'Each',
                maica_cc__Active__c = true
        );
        insert supportItemVar;
    }

    @IsTest
    static void testInsertBehaviour() {
        Response resp = new SyncProductsBatch().process(new Request());
        Assert.isTrue(resp.isValid);

        Test.startTest();
        String jobId = ScheduleManager.schedule(
                ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME,
                Time.newInstance(4, 0, 0, 0),
                new SyncProductsBatch()
        );
        CronTrigger ct = (CronTrigger) Utils.arrays.firstOrNull([
                SELECT Id
                FROM CronTrigger
                WHERE Id = :jobId
        ]);
        Assert.isNotNull(ct);
        Database.executeBatch(new SyncProductsBatch(true), 100);
        Test.stopTest();

        maica_cc__Support_Item__c supportItemVar = (maica_cc__Support_Item__c) Utils.arrays.firstOrException([
                SELECT Id, Product__c, maica_cc__Support_Category__c, maica_cc__Service_Day__c,
                        maica_cc__Service_Time__c, maica_cc__Quantity_Unit_Of_Measure__c, maica_cc__Active__c
                FROM maica_cc__Support_Item__c
        ], 'No maica_cc__Support_Item__c.');

        List<Product2> products = [
                SELECT Id, Support_Item__c
                FROM Product2
                WHERE Support_Item__c = :supportItemVar.Id
        ];

        Product2 product2Var = (Product2) Utils.arrays.firstOrNull([
                SELECT Id, Support_Item__c, Support_Category__c, Service_Day__c, Service_Time__c,
                        QuantityUnitOfMeasure, IsActive
                FROM Product2
                WHERE Id IN (SELECT Product__c FROM maica_cc__Support_Item__c WHERE Id = :supportItemVar.Id)
                AND Support_Item__c = :supportItemVar.Id
        ]);

        Assert.isTrue(products.size() == 1);
        Assert.isTrue(product2Var != null);
        Assert.isTrue(supportItemVar.Id.equals(product2Var.Support_Item__c));
        Assert.isTrue(product2Var.Id.equals(supportItemVar.Product__c));
        Assert.isTrue(product2Var.IsActive == true && supportItemVar.maica_cc__Active__c.equals(product2Var.IsActive));
        Assert.isTrue(supportItemVar.maica_cc__Quantity_Unit_Of_Measure__c.equals(product2Var.QuantityUnitOfMeasure));
        Assert.isTrue(supportItemVar.maica_cc__Service_Day__c.equals(product2Var.Service_Day__c));
        Assert.isTrue(supportItemVar.maica_cc__Service_Time__c.equals(product2Var.Service_Time__c));
        Assert.isTrue(supportItemVar.maica_cc__Support_Category__c.equals(product2Var.Support_Category__c));
    }

    @IsTest
    static void testUpdateBehaviour() {
        maica_cc__Support_Item__c supportItemVar = (maica_cc__Support_Item__c) Utils.arrays.firstOrException([
                SELECT Id, Product__c, maica_cc__Support_Category__c, maica_cc__Service_Day__c,
                        maica_cc__Service_Time__c, maica_cc__Quantity_Unit_Of_Measure__c, maica_cc__Active__c
                FROM maica_cc__Support_Item__c
        ], 'No maica_cc__Support_Item__c.');
        supportItemVar.maica_cc__Service_Time__c = 'Daytime';
        update supportItemVar;

        Test.startTest();
        Database.executeBatch(new SyncProductsBatch(), 100);
        Test.stopTest();

        Product2 product2Var = (Product2) Utils.arrays.firstOrNull([
                SELECT Id, Service_Time__c
                FROM Product2
                WHERE Id IN (SELECT Product__c FROM maica_cc__Support_Item__c WHERE Id = :supportItemVar.Id)
                AND Support_Item__c = :supportItemVar.Id
        ]);

        Assert.isTrue('Daytime'.equals(supportItemVar.maica_cc__Service_Time__c) && supportItemVar.maica_cc__Service_Time__c.equals(product2Var.Service_Time__c));
    }

    @IsTest
    static void testDelete() {
        maica_cc__Support_Item__c supportItemVar = (maica_cc__Support_Item__c) Utils.arrays.firstOrException([
                SELECT Id, Product__c, maica_cc__Support_Category__c, maica_cc__Service_Day__c,
                        maica_cc__Service_Time__c, maica_cc__Quantity_Unit_Of_Measure__c, maica_cc__Active__c
                FROM maica_cc__Support_Item__c
        ], 'No maica_cc__Support_Item__c.');
        delete supportItemVar;

        Test.startTest();
        Database.executeBatch(new SyncProductsBatch(), 100);
        Test.stopTest();

        Product2 product2Var = (Product2) Utils.arrays.firstOrNull([
                SELECT Id
                FROM Product2
                WHERE Id IN (SELECT Product__c FROM maica_cc__Support_Item__c WHERE Id = :supportItemVar.Id)
                AND Support_Item__c = :supportItemVar.Id
        ]);
        Assert.isNull(product2Var);
    }

    @IsTest
    static void testCatch() {
        SyncProductsBatch bc = new SyncProductsBatch();
        bc.execute(null, null);
        maica_cc__Log__c log = (maica_cc__Log__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Details__c
                FROM maica_cc__Log__c
        ]);
        Assert.isNotNull(log);
        Assert.areEqual('Attempt to de-reference a null object', log.maica_cc__Details__c, 'Error message should be \'Attempt to de-reference a null object\'');
    }
}