@IsTest
private class MDTM_SyncPriceListsTest {

    @IsTest
    static void testBehaviour() {
        setupTestHandlers();

        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Standard to Maica';
        setting.Sync_Mode__c = 'Triggered';
        upsert setting;
        
        Pricebook2 pbVar = new Pricebook2(
                Name = 'Test Pricebook2',
                IsActive = true
        );
        insert pbVar;

        pbVar = (Pricebook2) Utils.arrays.firstOrException([
                SELECT Id, Price_List__c, Name, IsActive
                FROM Pricebook2
                WHERE Id = :pbVar.Id
        ], 'No Pricebook2 with Id: ' + pbVar.Id);

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

        pbVar.Name = 'Test Pricebook2 Test';
        update pbVar;

        priceListVar = (maica_cc__Price_List__c) Utils.arrays.firstOrNull([
                SELECT Id, Name
                FROM maica_cc__Price_List__c
                WHERE Id IN (SELECT Price_List__c FROM Pricebook2 WHERE Id = :pbVar.Id)
                AND Price_Book__c = :pbVar.Id
        ]);

        Assert.isTrue('Test Pricebook2 Test'.equals(pbVar.Name) && pbVar.Name.equals(priceListVar.Name));

        delete pbVar;
        priceListVar = (maica_cc__Price_List__c) Utils.arrays.firstOrNull([
                SELECT Id
                FROM maica_cc__Price_List__c
                WHERE Id IN (SELECT Price_List__c FROM Pricebook2 WHERE Id = :pbVar.Id)
                AND Price_Book__c = :pbVar.Id
        ]);
        Assert.isNull(priceListVar);
    }

    static void setupTestHandlers() {
        maica_cc.MDTM.setupTestHandlers(new List<maica_cc__Trigger_Handler__mdt>{
                new maica_cc__Trigger_Handler__mdt(
                        maica_cc__Object__c = '' + Pricebook2.SObjectType,
                        maica_cc__Class__c = '' + MDTM_SyncPriceLists.class,
                        maica_cc__Active__c = true
                )
        });
    }
}