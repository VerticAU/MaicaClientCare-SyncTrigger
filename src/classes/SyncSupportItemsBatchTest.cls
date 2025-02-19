@IsTest
private class SyncSupportItemsBatchTest {

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
                Service_Time__c = 'Anytime',
                QuantityUnitOfMeasure = 'Each',
                IsActive = true
        );
        insert product2Var;
    }

    @IsTest
    static void testInsertBehaviour() {
        Response resp = new SyncSupportItemsBatch().process(new Request());
        Assert.isTrue(resp.isValid);

        Test.startTest();
        String jobId = ScheduleManager.schedule(
                ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME,
                Time.newInstance(4, 0, 0, 0),
                new SyncSupportItemsBatch()
        );
        CronTrigger ct = (CronTrigger) Utils.arrays.firstOrNull([
                SELECT Id
                FROM CronTrigger
                WHERE Id = :jobId
        ]);
        Assert.isNotNull(ct);
        Database.executeBatch(new SyncSupportItemsBatch(true), 1);
        Test.stopTest();

        Product2 product2Var = (Product2) Utils.arrays.firstOrException([
                SELECT Id, Support_Item__c, Support_Category__c,
                        Service_Day__c, Service_Time__c, QuantityUnitOfMeasure, IsActive
                FROM Product2
        ], 'No Product2 record.');

        List<maica_cc__Support_Item__c> supportItems = [
                SELECT Id, Product__c, maica_cc__Support_Category__c, maica_cc__Service_Day__c,
                        maica_cc__Service_Time__c, maica_cc__Quantity_Unit_Of_Measure__c, maica_cc__Active__c
                FROM maica_cc__Support_Item__c
                WHERE Id IN (SELECT Support_Item__c FROM Product2 WHERE Id = :product2Var.Id)
                AND Product__c = :product2Var.Id
        ];

        Assert.isTrue(!supportItems.isEmpty());
        Assert.isTrue(supportItems.size() == 1);
        maica_cc__Support_Item__c supportItemVar = supportItems[0];
        Assert.isTrue(product2Var.Id.equals(supportItemVar.Product__c));
        Assert.isTrue(supportItemVar.Id.equals(product2Var.Support_Item__c));
        Assert.isTrue(supportItemVar.maica_cc__Active__c == true && product2Var.IsActive.equals(supportItemVar.maica_cc__Active__c));
        Assert.isTrue(product2Var.Service_Day__c.equals(supportItemVar.maica_cc__Service_Day__c));
        Assert.isTrue(product2Var.Service_Time__c.equals(supportItemVar.maica_cc__Service_Time__c));
        Assert.isTrue(product2Var.Support_Category__c.equals(supportItemVar.maica_cc__Support_Category__c));
        Assert.isTrue(product2Var.QuantityUnitOfMeasure.equals(supportItemVar.maica_cc__Quantity_Unit_Of_Measure__c));
    }

    @IsTest
    static void testUpdateBehaviour() {
        Product2 product2Var = (Product2) Utils.arrays.firstOrException([
                SELECT Id, Support_Item__c, Support_Category__c,
                        Service_Day__c, Service_Time__c, QuantityUnitOfMeasure, IsActive
                FROM Product2
        ], 'No Product2 record.');
        product2Var.Service_Time__c = 'Daytime';
        update product2Var;

        Test.startTest();
        Database.executeBatch(new SyncSupportItemsBatch(), 1);
        Test.stopTest();

        maica_cc__Support_Item__c supportItemVar = (maica_cc__Support_Item__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Service_Time__c
                FROM maica_cc__Support_Item__c
                WHERE Id IN (SELECT Support_Item__c FROM Product2 WHERE Id = :product2Var.Id)
                AND Product__c = :product2Var.Id
        ]);

        Assert.isTrue('Daytime'.equals(product2Var.Service_Time__c) && product2Var.Service_Time__c.equals(supportItemVar.maica_cc__Service_Time__c));
    }

    @IsTest
    static void testDelete() {
        Product2 product2Var = (Product2) Utils.arrays.firstOrException([
                SELECT Id, Support_Item__c, Support_Category__c,
                        Service_Day__c, Service_Time__c, QuantityUnitOfMeasure, IsActive
                FROM Product2
        ], 'No Product2 record.');

        delete product2Var;

        Test.startTest();
        Database.executeBatch(new SyncSupportItemsBatch(), 1);
        Test.stopTest();

        maica_cc__Support_Item__c supportItemVar = (maica_cc__Support_Item__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Support_Item__c
                WHERE Id IN (SELECT Support_Item__c FROM Product2 WHERE Id = :product2Var.Id)
                AND Product__c = :product2Var.Id
        ]);
        Assert.isNull(supportItemVar);
    }

    @IsTest
    static void testCatch() {
        SyncSupportItemsBatch bc = new SyncSupportItemsBatch();
        bc.execute(null, null);
        maica_cc__Log__c log = (maica_cc__Log__c)Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Details__c
                FROM maica_cc__Log__c
        ]);
        Assert.isNotNull(log);
        Assert.areEqual('Attempt to de-reference a null object', log.maica_cc__Details__c, 'Error message should be \'Attempt to de-reference a null object\'');
    }
}