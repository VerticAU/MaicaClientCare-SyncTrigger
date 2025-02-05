public without sharing class SettingsSyncSubmitProc extends AbstractProcessor {

    public override Response process(Request request) {
        this.request = request;

        this.doSubmit();

        return this.response;
    }

    private void doSubmit() {
        maica_cc__Setting__c setting = MaicaSetting.sync;
        this.request.getMapper().mapToSObject('setting', setting);
        upsert setting;

        Time syncTime = this.request.getTime('syncTime');
        syncTime = syncTime == null ? Time.newInstance(4, 0, 0, 0) : syncTime;
//        Time entriesSyncTime = this.request.getTime('entriesSyncTime');
//        entriesSyncTime = entriesSyncTime == null ? Time.newInstance(1, 0, 0, 0) : entriesSyncTime;

//        if ('Triggered'.equals(setting.Sync_Mode__c) && 'Standard to Maica'.equals(setting.Sync_Direction__c)) {
//            CronTrigger syncCronTrigger = ScheduleManager.getScheduled(ScheduleManager.SYNC_PRICE_LIST_ENTRIES_SCHEDULED_JOB_NAME);
//            Time currentSyncTime = syncCronTrigger?.NextFireTime?.time();
//            if (currentSyncTime == null || currentSyncTime != entriesSyncTime) {
//                ScheduleManager.stop(ScheduleManager.SYNC_PRICE_LIST_ENTRIES_SCHEDULED_JOB_NAME);
//                ScheduleManager.schedule(
//                        ScheduleManager.SYNC_PRICE_LIST_ENTRIES_SCHEDULED_JOB_NAME,
//                        entriesSyncTime,
//                        new SyncPriceListEntriesBatch()
//                );
//            }
//        } else {
//            ScheduleManager.stop(ScheduleManager.SYNC_PRICE_LIST_ENTRIES_SCHEDULED_JOB_NAME);
//        }
        if ('Scheduled'.equals(setting.Sync_Mode__c)) {
            CronTrigger syncCronTrigger = ScheduleManager.getScheduled(ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME);
            Time currentSyncTime = syncCronTrigger?.NextFireTime?.time();
            if (currentSyncTime == null || currentSyncTime != syncTime) {
                ScheduleManager.stop(ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME);
                ScheduleManager.schedule(
                        ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME,
                        syncTime,
                        'Standard to Maica'.equals(setting.Sync_Direction__c) ? (Schedulable) new SyncSupportItemsBatch() : (Schedulable) new SyncProductsBatch()
                );
            }
        } else {
            ScheduleManager.stop(ScheduleManager.SYNC_ALL_OBJECTS_JOB_NAME);
        }
    }
}