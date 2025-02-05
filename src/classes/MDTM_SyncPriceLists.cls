global without sharing class MDTM_SyncPriceLists extends maica_cc.MDTM.Handler implements maica_cc.MDTM.AfterInsert, maica_cc.MDTM.AfterUpdate, maica_cc.MDTM.AfterDelete {

    public void onAfterInsert(List<SObject> records) {
        if('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Standard to Maica'.equals(MaicaSetting.sync?.Sync_Direction__c)){
            sync(records);
        }
    }

    public void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecordsMap) {
        if('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Standard to Maica'.equals(MaicaSetting.sync?.Sync_Direction__c)){
            sync(records);
        }
    }

    public void onAfterDelete(List<SObject> records) {
        if('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Standard to Maica'.equals(MaicaSetting.sync?.Sync_Direction__c)){
            sync(records);
        }
    }

    public static void sync(List<SObject> records) {
        new SyncObjectsProc().process(new Map<String, Object>{
                'sObjectType1' => 'Pricebook2',
                'relationshipFieldToObj2Str' => 'Price_List__c',
                'sObjectType2' => 'maica_cc__Price_List__c',
                'relationshipFieldToObj1Str' => 'Price_Book__c',
                'obj1Records' => new AutoMapper().getSObjectsAsMaps(records),
                'isDelete' => Trigger.isDelete == true,
                'isCustomToStandard' => false,
                'differentFieldsMap' => new Map<String, Object>{
                        'maica_cc__Active__c' => 'IsActive'
                }
        });
    }
}