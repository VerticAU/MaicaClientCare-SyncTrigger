public without sharing class SettingsSyncMetaProc extends MetadataProcessor {

    public override Response process(Request request) {
        this.request = request == null ? new MetadataProcessor.MetadataRequest() : (MetadataProcessor.MetadataRequest) request;

        this.request.fields = new Set<SObjectField>{
                maica_cc__Setting__c.Sync_Mode__c,
                maica_cc__Setting__c.Sync_Direction__c
        };

        super.process(this.request);

        this.init();

        return this.response;
    }

    private void init() {
        maica_cc__Setting__c setting = MaicaSetting.sync;
        this.response.getMapper().mapFromSObject('setting', setting);

        CronTrigger syncCronTrigger = ScheduleManager.getScheduled(ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME);
        Time syncTime = syncCronTrigger?.NextFireTime?.time();
        if (syncTime == null) {
            syncTime = Time.newInstance(4, 0, 0, 0);
        }
        this.response.put('syncTime', syncTime);

        CronTrigger entriesSyncCronTrigger = ScheduleManager.getScheduled(ScheduleManager.SYNC_PRICE_LIST_ENTRIES_SCHEDULED_JOB_NAME);
        Time entriesSyncTime = entriesSyncCronTrigger?.NextFireTime ?.time();
        if (entriesSyncTime == null) {
            entriesSyncTime = Time.newInstance(4, 0, 0, 0);
        }
        this.response.put('entriesSyncTime', entriesSyncTime);
    }
}