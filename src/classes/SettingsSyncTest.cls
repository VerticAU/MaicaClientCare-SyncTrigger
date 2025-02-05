@IsTest
private class SettingsSyncTest {

    @IsTest
    static void testMetaProc() {
        Response resp = new SettingsSyncMetaProc().process(new MetadataProcessor.MetadataRequest());
        Assert.isTrue(resp.isValid);
        Assert.areEqual(resp.getTime('syncTime'), Time.newInstance(4, 0, 0, 0), 'Sync time should be 4:00:00');
        Assert.areEqual(resp.getTime('entriesSyncTime'), Time.newInstance(4, 0, 0, 0), 'Sync time should be 4:00:00');
    }

    @IsTest
    static void testSubmitProc() {
        MaicaSetting.CACHING = false;
        maica_cc__Setting__c setting = new maica_cc__Setting__c();
        setting.maica_cc__API_Name__c = MaicaSetting.SYNC_SETTING;
        setting.Sync_Direction__c = 'Standard to Maica';
        setting.Sync_Mode__c = 'Scheduled';
        upsert setting;

        Test.startTest();
        Response resp = new SettingsSyncSubmitProc().process(new Map<String, Object>{
                'setting' =>  new AutoMapper().getSObjectAsMap(setting)

        });
        CronTrigger ct = (CronTrigger) Utils.arrays.firstOrNull([
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = :ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME
        ]);
        Assert.isNotNull(ct);
        Test.stopTest();

        setting.Sync_Mode__c = 'Triggered';
        upsert setting;

        resp = new SettingsSyncSubmitProc().process(new Map<String, Object>{
                'setting' =>  new AutoMapper().getSObjectAsMap(setting)
        });
        ct = (CronTrigger) Utils.arrays.firstOrNull([
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = :ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME
        ]);
        Assert.isNull(ct);
        Assert.isTrue(resp.isValid);
    }
}