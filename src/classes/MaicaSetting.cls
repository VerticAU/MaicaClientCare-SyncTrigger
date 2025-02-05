public without sharing class MaicaSetting {

    public static Boolean CACHING = true;

    public static Map<String, maica_cc__Setting__c> settingMap {
        get {
            if (settingMap == null) {
                initSettingMap();
            }
            return settingMap;
        }
        private set;
    }

    public static final List<FieldDefinition> settingFieldsDefs {
        get {
            if (settingFieldsDefs == null || !CACHING) {
                settingFieldsDefs = [
                        SELECT Label, QualifiedApiName, Description, DataType
                        FROM FieldDefinition
                        WHERE EntityDefinition.QualifiedApiName = 'maica_cc__Setting__c'
                        AND QualifiedApiName != 'UserRecordAccessId'
                ];
            }
            return settingFieldsDefs;
        }
        private set;
    }

    public final static String SYNC_SETTING = 'Sync_Setting';

    public static maica_cc__Setting__c sync {
        get {
            if (sync == null || !CACHING) {
                sync = settingMap.get(SYNC_SETTING);
            }
            return (sync == null ? new maica_cc__Setting__c(maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING) : sync);
        }
        private set;
    }

    private static void initSettingMap() {
        settingMap = new Map<String, maica_cc__Setting__c>();
        fflib_QueryFactory queryFactory = new fflib_QueryFactory(maica_cc__Setting__c.SObjectType);
        for (SObjectField field : maica_cc__Setting__c.SObjectType.getDescribe().fields.getMap().values()) {
            if (field.getDescribe().isCustom()) {
                queryFactory.selectField(field);
            }
        }
        queryFactory.setAccessLevel(AccessLevel.SYSTEM_MODE); // CRUD/FLS/Query/Sharing False Positive: This query should have a system permission to be able to query setting records for application to work properly.
        for (maica_cc__Setting__c setting : Database.query(queryFactory.toSOQL())) {
            settingMap.put(setting.maica_cc__API_Name__c, setting);
        }
    }

    public static void reInitSettingMap() {
        initSettingMap();
    }

    public static void initSetting(String settingAPIName) {
        SObject defaultSetting = maica_cc__Setting__c.SObjectType.newSObject(null, true);
        maica_cc__Setting__c setting = settingMap.get(settingAPIName);
        setting = setting == null ? new maica_cc__Setting__c(maica_cc__API_Name__c = settingAPIName) : setting;

        for (FieldDefinition fieldDef : settingFieldsDefs) {
            String type = fieldDef.DataType;
            String fieldName = fieldDef.QualifiedApiName;
            String fieldDescription = fieldDef.Description; //can be retrieved only from FieldDefinition sObject
            Object defaultValue = defaultSetting.get(fieldName);

            if (setting.get(fieldName) == null && fieldDescription != null && defaultValue != null) {
                if (fieldDescription.contains('Setting API Name:' + settingAPIName)) {
                    setting.put(fieldName, defaultValue);
                } else {
                    setting.put(fieldName, 'Checkbox'.equals(type) ? false : null);
                }
            }
        }

        upsert setting;
    }
}