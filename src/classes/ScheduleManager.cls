public without sharing class ScheduleManager {

    public static final String SYNC_PRICE_LIST_ENTRIES_SCHEDULED_JOB_NAME = 'Sync Price List Entries';
    public static final String SYNC_ALL_OBJECTS_JOB_NAME = 'Sync All Objects';

    public static final Map<String, Object> SCHEDULERS = new Map<String, Object>{

    };

    public static void restart() {
        stopAll();
        startAll();
    }

    public static void start(String jobName) {
        Map<String, Object> scheduleSetting = (Map<String, Object>) SCHEDULERS.get(jobName);
        Type typeVar = (Type) scheduleSetting.get('type');

        System.schedule(
                jobName,
                (String) scheduleSetting.get('cron'),
                (Schedulable) typeVar.newInstance()
        );
    }

    public static void stop(String jobName) {
        CronTrigger cronTrigger = (CronTrigger)Utils.arrays.firstOrNull([
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
        ]);
        if(cronTrigger != null){
            System.abortJob(cronTrigger.Id);
        }
    }

    public static void reRun(String jobName) {
        stop(jobName);
        start(jobName);
    }

    public static void startAll() {
        for (String jobName : SCHEDULERS.keySet()) {
            start(jobName);
        }
    }

    public static void stopAll() {
        for (CronTrigger delCron : [
                SELECT Id
                FROM CronTrigger
                WHERE CronJobDetail.Name IN :SCHEDULERS.keySet()
        ]) {
            System.abortJob(delCron.Id);
        }
    }

    public static Id schedule(String jobName, Time timeVar, Schedulable scheduler) {
        return schedule(jobName, String.format('0 {1} {0} * * ? *', new List<String>{
                '' + timeVar.hour(),
                '' + timeVar.minute()
        }), scheduler);
    }

    public static Id schedule(String jobName, String cron, Schedulable scheduler) {
        return System.schedule(
                jobName,
                cron,
                scheduler
        );
    }

    public static CronTrigger getScheduled(String jobName) {
        return (CronTrigger) Utils.arrays.firstOrNull([
                SELECT Id, NextFireTime
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName
        ]
        );
    }

}