trigger PriceListEntryTrigger on maica_cc__Price_List_Entry__c (after insert, after update, after delete) {
    try {
        maica_cc.MDTM.handle();
    } catch (Exception e) {
        if (Trigger.new != null) {
            for (SObject record : Trigger.new) {
                record.addError(e.getMessage());
            }
        } else if(Trigger.old != null){
            for (SObject record : Trigger.old) {
                record.addError(e.getMessage());
            }
        } else {
            throw new Structs.ValidationException(e.getMessage());
        }
    }
}