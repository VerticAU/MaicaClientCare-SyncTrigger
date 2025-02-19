global without sharing class MDTM_SyncProducts extends maica_cc.MDTM.Handler implements maica_cc.MDTM.AfterInsert, maica_cc.MDTM.AfterUpdate, maica_cc.MDTM.AfterDelete {

    public void onAfterInsert(List<SObject> records) {
        if('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Maica to Standard'.equals(MaicaSetting.sync?.Sync_Direction__c)){
            sync(records);
        }
    }

    public void onAfterUpdate(List<SObject> records, Map<Id, SObject> existingRecordsMap) {
        if('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Maica to Standard'.equals(MaicaSetting.sync?.Sync_Direction__c)){
            sync(records);
        }
    }

    public void onAfterDelete(List<SObject> records) {
        if('Triggered'.equals(MaicaSetting.sync?.Sync_Mode__c) && 'Maica to Standard'.equals(MaicaSetting.sync?.Sync_Direction__c)){
            sync(records);
        }
    }

    public static void sync(List<SObject> records) {
//        try{
            new SyncObjectsProc().process(new Map<String, Object>{
                    'sObjectType1' => 'maica_cc__Support_Item__c',
                    'relationshipFieldToObj2Str' => 'Product__c',
                    'sObjectType2' => 'Product2',
                    'relationshipFieldToObj1Str' => 'Support_Item__c',
                    'obj1Records' => new AutoMapper().getSObjectsAsMaps(records),
                    'isDelete' => Trigger.isDelete == true,
                    'isCustomToStandard' => true,
                    'differentFieldsMap' => new Map<String, Object>{
                            'maica_cc__Active__c' => 'IsActive'
                    }
            });
//        } catch (Exception e) {
//            System.debug('here');
//            if(Trigger.new != null){
//                for(SObject record :Trigger.new){
//                    record.addError(e.getMessage());
//                }
//            }
//        }
    }
}