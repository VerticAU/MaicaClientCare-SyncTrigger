global without sharing class MDTM_SyncSupportItems extends maica_cc.MDTM.Handler implements maica_cc.MDTM.AfterInsert, maica_cc.MDTM.AfterUpdate, maica_cc.MDTM.AfterDelete {

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
                'sObjectType1' => 'Product2',
                'relationshipFieldToObj2Str' => 'Support_Item__c',
                'sObjectType2' => 'maica_cc__Support_Item__c',
                'relationshipFieldToObj1Str' => 'Product__c',
                'obj1Records' => new AutoMapper().getSObjectsAsMaps(records),
                'isDelete' => Trigger.isDelete == true,
                'isCustomToStandard' => false,
                'differentFieldsMap' => new Map<String, Object>{
                        'maica_cc__Active__c' => 'IsActive'
                }
        });
    }
}