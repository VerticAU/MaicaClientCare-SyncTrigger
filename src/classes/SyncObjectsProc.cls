public with sharing class SyncObjectsProc extends AbstractProcessor {

    private Boolean isDelete;
    private String namespace;
    private Map<String, Object> bindObj1RecordsMap;
    private Boolean isCustomToStandard;
    private Map<String, Object> differentFieldsMap;

    public override Response process(Request request) {
        this.request = request;
        this.sync();
        return this.response;
    }

    private void sync() {
        this.isDelete = this.request.getBoolean('isDelete') == true;
        this.isCustomToStandard = this.request.getBoolean('isCustomToStandard') == true;
        this.namespace = Utils.objects.defaultIfNull(this.request.getString('namespace'), '');
        this.differentFieldsMap = this.request.getMap('differentFieldsMap');
        this.differentFieldsMap = this.differentFieldsMap == null ? new Map<String, Object>() : this.differentFieldsMap;

        String sObjectType1Str = this.request.getRequiredString('sObjectType1');
        SObjectType sObjectType1 = Schema.getGlobalDescribe().get(sObjectType1Str.toLowerCase());
        Utils.objects.throwIfNull(sObjectType1, 'No SObjectType with API Name: ' + sObjectType1Str);
        Type sObject1Type = Type.forName('Schema.' + sObjectType1Str);
        Utils.objects.throwIfNull(sObject1Type, 'No SObjectType with API Name: ' + sObjectType1Str);

        String sObjectType2Str = this.request.getRequiredString('sObjectType2');
        SObjectType sObjectType2 = Schema.getGlobalDescribe().get(sObjectType2Str.toLowerCase());
        Utils.objects.throwIfNull(sObjectType2, 'No SObjectType with API Name: ' + sObjectType2Str);
        Type sObject2Type = Type.forName('Schema.' + sObjectType2Str);
        Utils.objects.throwIfNull(sObject2Type, 'No SObjectType with API Name: ' + sObjectType2Str);

        String relationshipFieldToObj1Str = this.request.getRequiredString('relationshipFieldToObj1Str');
        SObjectField relationshipFieldToObj1 = sObjectType2.getDescribe().fields.getMap().get(relationshipFieldToObj1Str);
        Utils.objects.throwIfNull(relationshipFieldToObj1, 'No SObjectField with API Name: ' + relationshipFieldToObj1Str + ' on SObjectType: ' + sObjectType2Str);

        String relationshipFieldToObj2Str = this.request.getRequiredString('relationshipFieldToObj2Str');
        SObjectField relationshipFieldToObj2 = sObjectType1.getDescribe().fields.getMap().get(relationshipFieldToObj2Str);
        Utils.objects.throwIfNull(relationshipFieldToObj2, 'No SObjectField with API Name: ' + relationshipFieldToObj2Str + ' on SObjectType: ' + sObjectType1Str);

        this.bindObj1RecordsMap = this.request.getMap('bindObj1RecordsMap');
        List<SObject> obj1Records = this.request.getMapper().mapToListSObjects('obj1Records', sObjectType1);
        List<String> objt2Ids = new List<String>(Utils.sObjects.getStringFieldValues(obj1Records, relationshipFieldToObj2));

        if (!this.isDelete) {
            Boolean isNew = false;
            UnitOfWork uow = new UnitOfWork(
                    new List<SObjectType>{
                            sObjectType2,
                            sObjectType1
                    }
            );
            fflib_QueryFactory queryFactory = new fflib_QueryFactory(sObjectType2);
            queryFactory.selectFields(SyncObjectsProc.getAvailableFields(sObjectType2).keySet());
            queryFactory.setCondition('Id IN :objt2Ids');
            Map<Id, SObject> obj2Map = new Map<Id, SObject>(Database.query(queryFactory.toSOQL()));

            for (SObject obj1 : obj1Records) {
                SObject obj2 = obj2Map.get((String) obj1.get(relationshipFieldToObj2Str));
                if (obj2 == null) {
                    obj2 = (SObject) sObject2Type.newInstance();
                    isNew = true;
                }
                Boolean isMapped = this.mapObj1ToObj2(obj1, obj2, isNew);
                if (isMapped == true) {
                    uow.registerUpsert(obj1);
                    uow.registerUpsert(obj2);
                    uow.registerRelationship(obj1, relationshipFieldToObj2, obj2);
                    uow.registerHierarchy(obj2, relationshipFieldToObj1, obj1);
                }
            }

            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncPriceLists.class).disableAll();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncSupportItems.class).disableAll();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncProducts.class).disableAll();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncPricebooks.class).disableAll();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncPricebookEntries.class).disableAll();
            uow.commitWork();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncSupportItems.class).enableAll();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncPriceLists.class).enableAll();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncProducts.class).enableAll();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncPricebooks.class).enableAll();
            maica_cc.MDTM.getTriggerHandlerEvent(MDTM_SyncPricebookEntries.class).enableAll();

        } else {
            fflib_QueryFactory queryFactory = new fflib_QueryFactory(sObjectType2);
            queryFactory.setCondition('Id IN :objt2Ids');
            delete Database.query(queryFactory.toSOQL());
        }
    }

    private Boolean mapObj1ToObj2(SObject obj1Var, SObject obj2Var, Boolean isNew) {
        isNew = isNew == null ? false : isNew;
        Map<String, SObjectField> obj1FieldsMap = obj1Var.getSObjectType().getDescribe().fields.getMap();
        Map<String, SObjectField> obj2FieldsMap = obj2Var.getSObjectType().getDescribe().fields.getMap();
        Boolean isMapped = false;

        for (SObjectField field1 : this.isCustomToStandard ? obj1FieldsMap.values() : obj2FieldsMap.values()) {
            Map<String, SObjectField> fieldsMap = this.isCustomToStandard ? obj2FieldsMap : obj1FieldsMap;
            String field1Str = field1.getDescribe().getName();
            String field2Str = field1Str;
            SObjectField field2 = fieldsMap.get(field2Str);

            if (field2 == null && field1Str.contains('__')) {
                field2Str = field2Str.substringAfter('__');
                field2 = fieldsMap.get(field2Str);
            }
            if (field2 == null && field1Str.contains('__c')) {
                field2Str = field2Str.substringBefore('__c');
                field2 = fieldsMap.get(field2Str);
            }
            if (field2 == null && field1Str.contains('_')) {
                field2Str = field2Str.replaceAll('_', '');
                field2 = fieldsMap.get(field2Str);
            }
            //if sync managed obj to unmanaged custom
            if (field2 == null) {
                field2Str = this.namespace + field1Str;
                field2 = fieldsMap.get(field2Str);
            }
            //if sync fields with different API names, like as maica_cc__Active__c to IsActive, maica_cc__Price_List__c to Pricebook2Id
            //for maica_cc__Price_List__c to Pricebook2Id need to also have bindObj1RecordsMap with Pricebook2Id values
            if (field2 == null) {
                field2Str = (String) this.differentFieldsMap.get(field1Str);
                field2 = fieldsMap.get(field2Str);
            }

            if (field2 != null) {
                Boolean isUpdatable = this.isCustomToStandard ? field2.getDescribe().isUpdateable() : field1.getDescribe().isUpdateable();
                Boolean isCreateable = this.isCustomToStandard ? field2.getDescribe().isCreateable() : field1.getDescribe().isUpdateable();

                if ((isUpdatable || (isNew && isCreateable)) && fieldsMap.containsKey(field2.getDescribe().getName().toLowerCase())) {
                    if (!this.isCustomToStandard) {
                        if (obj1Var.get(field2) != obj2Var.get(field1)) {
                            Object val = obj1Var.get(field2);
                            obj2Var.put(field1Str, val);
                            if (val instanceof String && val != null) {
                                if (field1.getDescribe().length < field2.getDescribe().length) {
                                    obj2Var.put(field1Str, ((String) val).left(field1.getDescribe().length));
                                }
                            }
                            isMapped = true;
                        }
                        if (this.bindObj1RecordsMap != null) {
                            Map<String, Object> obj1Map = (Map<String, Object>) this.bindObj1RecordsMap.get((String) obj1Var.get('Id'));
                            Boolean containsField = obj1Map.containsKey(field1Str);
                            if (containsField && obj1Map.get(field1Str) != obj2Var.get(field1)) {
                                Object val = obj1Map.get(field1Str);
                                obj2Var.put(field1Str, val);
                                isMapped = true;
                            }
                        }
                    } else {
                        if (obj1Var.get(field1) != obj2Var.get(field2)) {
                            Object val = obj1Var.get(field1);
                            obj2Var.put(field2Str, val);
                            if (val instanceof String && val != null) {
                                if (field2.getDescribe().length < field1.getDescribe().length) {
                                    obj2Var.put(field2Str, ((String) val).left(field2.getDescribe().length));
                                }
                            }
                            isMapped = true;
                        }
                        if (this.bindObj1RecordsMap != null) {
                            Map<String, Object> obj1Map = (Map<String, Object>) this.bindObj1RecordsMap.get((String) obj1Var.get('Id'));
                            Boolean containsField = obj1Map.containsKey(field2Str);
                            if (containsField && obj1Map.get(field2Str) != obj2Var.get(field2)) {
                                Object val = obj1Map.get(field2Str);
                                obj2Var.put(field2Str, val);
                                isMapped = true;
                            }
                        }
                    }
                }
            }
        }
        return isMapped;
    }

    public static Map<String, SObjectField> getAvailableFields(SObjectType sObjectTypeVar) {
        Map<String, SObjectField> fieldsMap = sObjectTypeVar.getDescribe().fields.getMap();
        Map<String, SObjectField> availableFieldsMap = new Map<String, SObjectField>();
        for (String fieldName : fieldsMap.keySet()) {
            SObjectField fieldVar = fieldsMap.get(fieldName);
            if (fieldVar.getDescribe().isAccessible() == true) {
                availableFieldsMap.put(fieldName, fieldVar);
            }
        }
        return availableFieldsMap;
    }
}