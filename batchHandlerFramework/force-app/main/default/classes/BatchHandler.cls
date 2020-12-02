public virtual class BatchHandler implements Database.Batchable<sObject>, Schedulable {
    private String query;
    private String batchScheduleKey;
    public void setQuery(String query) {
        this.query = query;
    }
    public void setScheduleMetadataKey(String batchScheduleKey) {
        this.batchScheduleKey = batchScheduleKey;
    }

    //Batch methods
    public System.Iterable<SObject> start(Database.BatchableContext bc) {
        if(query == null) throw new BatchHandlerException(NO_QUERY_STR_EXCEPTION);
        try {
            Database.QueryLocator ql = Database.getQueryLocator(query);
            return ql;
        } catch(QueryException qe) {
            throw new BatchHandlerException(INVALID_QUERY_STR_EXCEPTION + ':' + qe.getMessage());
        }
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        this.runBatch(scope);
    }
    public void finish(Database.BatchableContext bc) {
        if(this.batchScheduleKey != null) {
            sObject s = MetadataHandler.getData('BatchHandlerSetting__mdt',batchScheduleKey);
            String nextRunId;
            if(s != null) {
                BatchHandlerSetting__mdt bhs = (BatchHandlerSetting__mdt) s;
                if(bhs.Recurring__c && bhs.Interval__c != null && bhs.Interval__c > 0) {
                    nextRunId = System.scheduleBatch(
                        this.initialize(), 
                        BATCH_HANDLER + '_' + this.batchScheduleKey, 
                        Integer.valueOf(bhs.Interval__c), 
                        bhs.BatchSize__c != null ? Integer.valueOf(bhs.BatchSize__c) : 200
                    );
                }
            }
            MetadataHandler.createUpdateMetadata(
                BATCH_HANDLER_SETTING,
                batchScheduleKey,
                new Map<String,Object>{
                    'LastRun__c' => Datetime.now(),
                    'JobId__c' => nextRunId
                }
            );
        }
    }


    //Schedulable methods
    public void execute(System.SchedulableContext sc) {
        this.runSched();
    }

    public virtual void runBatch(List<SObject> scope) {
        throw new BatchHandlerException(RUNBATCH_NO_OVERRIDE);
    }
    public virtual void runSched() {
        this.runNow();
    }
    public virtual Database.Batchable<sObject> initialize() {
        throw new BatchHandlerException(RESCHEDULE_NO_OVERRIDE);
    }
    public String runNow() {
        return Database.executeBatch(this);
    }
    public class BatchHandlerException extends Exception {}
    private static final String NO_QUERY_STR_EXCEPTION = 'Query string not set. Use the setQuery method to define the batch job query.';
    private static final String INVALID_QUERY_STR_EXCEPTION = 'The query string is invalid.';
    private static final String RESCHEDULE_NO_OVERRIDE = 'The Extension class must override the method [Database.Batchable<sObject> initialize()]';
    private static final String RUNBATCH_NO_OVERRIDE = 'The Extension class must override the method [void runBatch(List<SObject> scope)]';
    private static final String BATCH_HANDLER_SETTING = 'BatchHandlerSetting';
    private static final String BATCH_HANDLER = 'BatchHandler';
}