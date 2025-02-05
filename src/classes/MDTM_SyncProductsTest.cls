@IsTest
private class MDTM_SyncProductsTest {

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
                maica_cc__Service_Time__c = 'Anytime',
                maica_cc__Quantity_Unit_Of_Measure__c = 'Each',
                maica_cc__Active__c = true
        );
        insert supportItemVar;

        List<Product2> products = [
                SELECT Id, Support_Item__c
                FROM Product2
                WHERE Support_Item__c = :supportItemVar.Id
        ];

        supportItemVar = (maica_cc__Support_Item__c) Utils.arrays.firstOrException([
                SELECT Id, Product__c, maica_cc__Support_Category__c, maica_cc__Service_Day__c,
                        maica_cc__Service_Time__c, maica_cc__Quantity_Unit_Of_Measure__c, maica_cc__Active__c
                FROM maica_cc__Support_Item__c
                WHERE Id = :supportItemVar.Id
        ], 'No maica_cc__Support_Item__c with Id: ' + supportItemVar.Id);

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

        supportItemVar.maica_cc__Service_Time__c = 'Daytime';
        update supportItemVar;

        product2Var = (Product2) Utils.arrays.firstOrNull([
                SELECT Id, Service_Time__c
                FROM Product2
                WHERE Id IN (SELECT Product__c FROM maica_cc__Support_Item__c WHERE Id = :supportItemVar.Id)
                AND Support_Item__c = :supportItemVar.Id
        ]);

        Assert.isTrue('Daytime'.equals(supportItemVar.maica_cc__Service_Time__c) && supportItemVar.maica_cc__Service_Time__c.equals(product2Var.Service_Time__c));

        delete supportItemVar;
        product2Var = (Product2) Utils.arrays.firstOrNull([
                SELECT Id
                FROM Product2
                WHERE Id IN (SELECT Product__c FROM maica_cc__Support_Item__c WHERE Id = :supportItemVar.Id)
                AND Support_Item__c = :supportItemVar.Id
        ]);
        Assert.isNull(product2Var);
    }

    static void setupTestHandlers() {
        maica_cc.MDTM.setupTestHandlers(new List<maica_cc__Trigger_Handler__mdt>{
                new maica_cc__Trigger_Handler__mdt(
                        maica_cc__Object__c = '' + maica_cc__Support_Item__c.SObjectType,
                        maica_cc__Class__c = '' + MDTM_SyncProducts.class,
                        maica_cc__Active__c = true,
                        maica_cc__Load_Order__c = 100
                )
        });
    }
}