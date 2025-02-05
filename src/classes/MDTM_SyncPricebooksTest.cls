@IsTest
private class MDTM_SyncPricebooksTest {

    @IsTest
    static void testBehaviour() {
        setupTestHandlers();

        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Maica to Standard';
        setting.Sync_Mode__c = 'Triggered';
        upsert setting;

        maica_cc__Price_List__c plVar = new maica_cc__Price_List__c(
                Name = 'Test Price List',
                maica_cc__Active__c = true
        );
        insert plVar;
        
        plVar = (maica_cc__Price_List__c) Utils.arrays.firstOrException([
                SELECT Id, Price_Book__c, Name, maica_cc__Active__c
                FROM maica_cc__Price_List__c
                WHERE Id = :plVar.Id
        ], 'No maica_cc__Price_List__c with Id: ' + plVar.Id);

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

        plVar.Name = 'Test Price List 1';
        update plVar;

        pbVar = (Pricebook2) Utils.arrays.firstOrNull([
                SELECT Id, Name
                FROM Pricebook2
                WHERE Id IN (SELECT Price_Book__c FROM maica_cc__Price_List__c WHERE Id = :plVar.Id)
                AND Price_List__c = :plVar.Id
        ]);
        Assert.isTrue('Test Price List 1'.equals(plVar.Name) && plVar.Name.equals(pbVar.Name));

        delete plVar;
        pbVar = (Pricebook2) Utils.arrays.firstOrNull([
                SELECT Id
                FROM Pricebook2
                WHERE Id IN (SELECT Price_Book__c FROM maica_cc__Price_List__c WHERE Id = :plVar.Id)
                AND Price_List__c = :plVar.Id
        ]);
        Assert.isNull(pbVar);
    }

    static void setupTestHandlers() {
        maica_cc.MDTM.setupTestHandlers(new List<maica_cc__Trigger_Handler__mdt>{
                new maica_cc__Trigger_Handler__mdt(
                        maica_cc__Object__c = '' + maica_cc__Price_List__c.SObjectType,
                        maica_cc__Class__c = '' + MDTM_SyncPricebooks.class,
                        maica_cc__Active__c = true
                )
        });
    }
}