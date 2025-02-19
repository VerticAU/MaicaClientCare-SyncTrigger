trigger PricebookTrigger on Pricebook2 (after insert, after update, after delete) {
    try {
        maica_cc.MDTM.handle();
    } catch (Exception e) {
        if (Trigger.new != null) {
            for (SObject record : Trigger.new) {
                record.addError(e.getMessage());
            }
        }
    }
}