public virtual class TriggerHandler {

    public class TriggerHandlerException extends Exception {}
    private static final String UNKNOWN_TRIGGER_EVENT = 'Unknown trigger event.';
    private static final String TRIGGER_NOT_ACTIVE = ' is not Active in the Trigger Handler Settings metadata.';
    private static final String TRIGGER_EVENT_NOT_ACTIVE = ' is disabled.';
    private static final String NO_TRIGGER_DEFINITION = ' was not found. The class must extend the TriggerHandler class and have a no-argument constructor.';
    private static final String TRIGGER_HANDLER_SETTING = 'TriggerHandlerSetting';
    private static final String CALL_NOT_IMPLEMENTED = 'The call method was not implemented on the extension class.';

    private String extensionClassName;
    private static List<String> breadCrumbs = new List<String>();
    private static Map<String,TriggerHandlerSetting__mdt> triggerSettings;
    public List<sObject> newList,oldList;
    public Map<Id,sObject> newMap, oldMap;
    private TriggerHandlerSetting__mdt ts;
    private static Map<String,Integer> usageTrack;
    private static Map<String,Integer> limitUsageTrack;
    private static List<String> logList;

    public static void initialize(String extensionClassName) {
        Type t = Type.forName(extensionClassName);
        TriggerHandler trig = (TriggerHandler)t.newInstance();
        try {
            trig.newList = Trigger.new;
            trig.oldList = Trigger.old;
            trig.newMap = Trigger.newMap;
            trig.oldMap = Trigger.oldMap;

            trig.run(extensionClassName);
        } catch(System.TypeException te) {
            throw new TriggerHandlerException(extensionClassName + ' ' + NO_TRIGGER_DEFINITION);
        }
    }

    private void log(String logStr) {
        if(this.ts.EnableLogging__c) System.debug('[' + this.ts.DeveloperName + '] ' + logStr);
    }
    private void logBreadCrumbs() {
        TriggerHandler.breadCrumbs.add(this.ts.DeveloperName + ':' + Trigger.operationType);
        String bc = '';
        for(Integer i = 0; i < TriggerHandler.breadCrumbs.size(); i+=1) {
            bc += TriggerHandler.breadCrumbs[i] + (i < TriggerHandler.breadCrumbs.size() - 1 ? ' > ':'');
        }
        this.log(bc);
    }


    private void logLimits() {
        String callouts = 'callouts',
                cpu_time = 'cpu time',
                dml_rows = 'dml rows',
                dml = 'dml',
                future = 'future calls',
                queries = 'queries',
                query_rows = 'query rows',
                queueable_jobs = 'queueable jobs';
        if(usageTrack == null) {
            usageTrack = new Map<String,Integer>();
            limitUsageTrack = new Map<String, Integer> { 
                callouts => Limits.getLimitCallouts(),
                cpu_time => Limits.getLimitCpuTime(),
                dml_rows => Limits.getLimitDMLRows(),
                dml => Limits.getLimitDMLStatements(),
                future => Limits.getLimitFutureCalls(),
                queries => Limits.getLimitQueries(),
                query_rows => Limits.getLimitQueryRows(),
                queueable_jobs => Limits.getLimitQueueableJobs()
            };
        }
        Map<String, Integer> triggerEventUsage = new Map<String,Integer>();

        if(usageTrack.containsKey(callouts)) triggerEventUsage.put(callouts, Limits.getCallouts() - usageTrack.get(callouts));
        else triggerEventUsage.put(callouts, Limits.getCallouts());
        usageTrack.put(callouts, Limits.getCallouts());

        if(usageTrack.containsKey(cpu_time)) triggerEventUsage.put(cpu_time, Limits.getCpuTime() - usageTrack.get(cpu_time));
        else triggerEventUsage.put(cpu_time, Limits.getCpuTime());
        usageTrack.put(cpu_time, Limits.getCpuTime());

        if(usageTrack.containsKey(dml_rows)) triggerEventUsage.put(dml_rows, Limits.getDMLRows() - usageTrack.get(dml_rows));
        else triggerEventUsage.put(dml_rows, Limits.getDMLRows());
        usageTrack.put(dml_rows, Limits.getDMLRows());

        if(usageTrack.containsKey(dml)) triggerEventUsage.put(dml, Limits.getDMLStatements() - usageTrack.get(dml));
        else triggerEventUsage.put(dml, Limits.getDMLStatements());
        usageTrack.put(dml, Limits.getDMLStatements());

        if(usageTrack.containsKey(future)) triggerEventUsage.put(future, Limits.getFutureCalls() - usageTrack.get(future));
        else triggerEventUsage.put(future, Limits.getFutureCalls());
        usageTrack.put(future, Limits.getFutureCalls());

        if(usageTrack.containsKey(queries)) triggerEventUsage.put(queries, Limits.getQueries() - usageTrack.get(queries));
        else triggerEventUsage.put(queries, Limits.getQueries());
        usageTrack.put(queries, Limits.getQueries());

        if(usageTrack.containsKey(query_rows)) triggerEventUsage.put(query_rows, Limits.getQueryRows() - usageTrack.get(query_rows));
        else triggerEventUsage.put(query_rows, Limits.getQueryRows());
        usageTrack.put(query_rows, Limits.getQueryRows());

        if(usageTrack.containsKey(queueable_jobs)) triggerEventUsage.put(queueable_jobs, Limits.getQueueableJobs() - usageTrack.get(queueable_jobs));
        else triggerEventUsage.put(queueable_jobs, Limits.getQueueableJobs());
        usageTrack.put(queueable_jobs, Limits.getQueueableJobs());

        for(String s : usageTrack.keySet()) {
            if(usageTrack.get(s) > 0) {
                this.log('[LIMIT:' + s.toUpperCase() + '] ' + ' : ' + '+' + triggerEventUsage.get(s) + ' : ' + usageTrack.get(s) +'/' + limitUsageTrack.get(s));
            }
        }
    }

    public void run(String extensionClassName) {
        this.ts = getSetting(extensionClassName);
        this.logBreadCrumbs();
        if(Trigger.isExecuting) {
            if(this.ts.Active__c) {
                switch on Trigger.operationType {
                    when BEFORE_INSERT { 
                        if(!ts.DisableBeforeInsert__c) this.bi(); 
                        else this.log(Trigger.operationType + TRIGGER_EVENT_NOT_ACTIVE);
                    }
                    when BEFORE_UPDATE {
                        if(!ts.DisableBeforeUpdate__c) this.bu(); 
                        else this.log(Trigger.operationType + TRIGGER_EVENT_NOT_ACTIVE);
                    } 
                    when BEFORE_DELETE {
                        if(!ts.DisableBeforeDelete__c) this.bd(); 
                        else this.log(Trigger.operationType + TRIGGER_EVENT_NOT_ACTIVE);
                    }
                    when AFTER_INSERT {
                        if(!ts.DisableAfterInsert__c) this.ai(); 
                        else this.log(Trigger.operationType + TRIGGER_EVENT_NOT_ACTIVE);
                    }
                    when AFTER_UPDATE {
                        if(!ts.DisableAfterUpdate__c) this.au(); 
                        else this.log(Trigger.operationType + TRIGGER_EVENT_NOT_ACTIVE);
                    } 
                    when AFTER_DELETE { 
                        if(!ts.DisableAfterDelete__c) this.ad(); 
                        else this.log(Trigger.operationType + TRIGGER_EVENT_NOT_ACTIVE);
                    } 
                    when AFTER_UNDELETE {
                        if(!ts.DisableAfterUndelete__c) this.aud(); 
                        else this.log(Trigger.operationType + TRIGGER_EVENT_NOT_ACTIVE);
                    }
                    when else {
                        throw new TriggerHandlerException(UNKNOWN_TRIGGER_EVENT);
                    }
                }

                this.log(this.ts.DeveloperName + ':' + Trigger.operationType + ' completed');

                if(this.ts.EnableLimitLogging__c) {
                    this.logLimits();
                }
            } 
            else {
                this.log(extensionClassName  + TRIGGER_NOT_ACTIVE);
            }
        }
    }

    private static TriggerHandlerSetting__mdt getSetting(String extensionClassName) {
        if(triggerSettings == null) {
            triggerSettings = (Map<String,TriggerHandlerSetting__mdt>) MetadataHandler.getAll('TriggerHandlerSetting__mdt');
        }
        if(!triggerSettings.containsKey(extensionClassName)) {
            runCreateUpdateMetadata(extensionClassName);
            triggerSettings.put(extensionClassName, 
                new TriggerHandlerSetting__mdt(
                    DeveloperName=extensionClassName,
                    Active__c=true,
                    EnableLogging__c=true
                )
            );
        }
        return triggerSettings.get(extensionClassName);
    }

    @future
    private static void runCreateUpdateMetadata(String extensionClassName) {
        MetadataHandler.createUpdateMetadata(
            TRIGGER_HANDLER_SETTING,
            extensionClassName,
            new Map<String,Object>{
                'Active__c' => true,
                'EnableLogging__c' => true
            }
        );
    }
    private void bi() { this.beforeInsert(); }
    private void bu() { this.beforeUpdate(); }
    private void bd() { this.beforeDelete(); }
    private void ai() { this.afterInsert(); }
    private void au() { this.afterUpdate(); }
    private void ad() { this.afterDelete(); }
    private void aud() { this.afterUndelete(); }

    //Overrideables
    public virtual void beforeInsert() {}
    public virtual void beforeUpdate() {}
    public virtual void beforeDelete() {}
    public virtual void afterInsert() {}
    public virtual void afterUpdate() {}
    public virtual void afterDelete() {}
    public virtual void afterUndelete() {}

    public virtual void call() {
        throw new TriggerHandlerException(extensionClassName + ' ' + CALL_NOT_IMPLEMENTED);
    }
}