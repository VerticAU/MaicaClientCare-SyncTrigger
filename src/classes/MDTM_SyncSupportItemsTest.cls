@IsTest
private class MDTM_SyncSupportItemsTest {

    @IsTest
    static void testBehaviour() {
        setupTestHandlers();

        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Standard to Maica';
        setting.Sync_Mode__c = 'Triggered';
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

        product2Var = (Product2) Utils.arrays.firstOrException([
                SELECT Id, Support_Item__c, Support_Category__c,
                        Service_Day__c, Service_Time__c, QuantityUnitOfMeasure, IsActive
                FROM Product2
                WHERE Id = :product2Var.Id
        ], 'No Product2 with Id: ' + product2Var.Id);

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

        product2Var.Service_Time__c = 'Daytime';
        update product2Var;

        supportItemVar = (maica_cc__Support_Item__c) Utils.arrays.firstOrNull([
                SELECT Id, maica_cc__Service_Time__c
                FROM maica_cc__Support_Item__c
                WHERE Id IN (SELECT Support_Item__c FROM Product2 WHERE Id = :product2Var.Id)
                AND Product__c = :product2Var.Id
        ]);

        Assert.isTrue('Daytime'.equals(product2Var.Service_Time__c) && product2Var.Service_Time__c.equals(supportItemVar.maica_cc__Service_Time__c));

        delete product2Var;
        supportItemVar = (maica_cc__Support_Item__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Support_Item__c
                WHERE Id IN (SELECT Support_Item__c FROM Product2 WHERE Id = :product2Var.Id)
                AND Product__c = :product2Var.Id
        ]);
        Assert.isNull(supportItemVar);
    }

    static void setupTestHandlers() {
        maica_cc.MDTM.setupTestHandlers(new List<maica_cc__Trigger_Handler__mdt>{
                new maica_cc__Trigger_Handler__mdt(
                        maica_cc__Object__c = '' + Product2.SObjectType,
                        maica_cc__Class__c = '' + MDTM_SyncSupportItems.class,
                        maica_cc__Active__c = true
                )
        });
    }
}