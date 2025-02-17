trigger PriceListTrigger on maica_cc__Price_List__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    try{
        maica_cc.MDTM.handle();
    } catch (Exception e) {
        List<SObject> records = Trigger.new != null ? Trigger.new : Trigger.old;
        for(SObject record :records){
            record.addError(e.getMessage());
        }
    }
}