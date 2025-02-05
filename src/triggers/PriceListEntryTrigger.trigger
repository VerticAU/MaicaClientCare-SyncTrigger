trigger PriceListEntryTrigger on maica_cc__Price_List_Entry__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    maica_cc.MDTM.handle();
}