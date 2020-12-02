public class MetadataHandler implements Metadata.DeployCallback {
    public class MetadataHandlerException extends Exception {}
    private static final String DEPLOY_FAILED = 'Metadata deployment failed.';
    private static Map<String, Map<String, sObject>> metadataSettings = new Map<String, Map<String, sObject>>();

    public static sObject getData(String metadataName, String recordName) {
        if(!metadataSettings.containsKey(metadataName)
            || 
            (metadataSettings.containsKey(metadataName) && !metadataSettings.get(metadataName).containsKey(recordName))) {
            try {
                getAll(metadataName);
            } catch(QueryException qe) {
                //TODO: THROW MESSAGE
            }
        }
        return metadataSettings.get(metadataName).get(recordName);
    }
    public static Map<String,sObject> getAll(String metadataName) {
        try {
            if(!metadataSettings.containsKey(metadataName)) metadataSettings.put(metadataName, new Map<String,sObject>());
            for(sObject s : Database.query(sObjectManager.createFullQuery(metadataName))) {
                metadataSettings.get(metadataName).put(String.valueOf(s.get('DeveloperName')),s);
            }
        } catch(QueryException qe) {
            //TODO: THROW MESSAGE
        }
        return metadataSettings.get(metadataName);
    }

    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        Id jobId = context.getCallbackJobId();

        CustomMetadataDeployment__e cmde = new CustomMetadataDeployment__e();
        cmde.JobId__c = jobId;
        cmde.isSuccess__c = result.status == Metadata.DeployStatus.Succeeded;
        cmde.Message__c = result.errorMessage;
        EventBus.publish(cmde);

        
        if (result.status != Metadata.DeployStatus.Succeeded) {
            throw new MetadataHandlerException(DEPLOY_FAILED + 'Error code: ' + result.errorStatusCode + ' Message: ' + result.errorMessage);
        }
    }

    public static String getDeployStatus(Id jobId) {
        String endPoint = URL.getOrgDomainUrl().toExternalForm() 
            + '/services/data/v50.0/tooling/query/?q=SELECT+Id,Status,StartDate,CompletedDate+FROM+DeployRequest+WHERE+Id=\''
            + jobId + '\'';
        
        Map<String, String> calloutHeaders = new Map<String,String> {
            'Authorization' => 'Bearer ' + UserInfo.getSessionID(),
            'Content-Type' => 'application/json'
        };
        HttpResponse hr = CalloutEngine.call(endPoint, 'GET', calloutHeaders,null);

        Map<String,Object> resp = (Map<String,Object>) JSON.deserializeUntyped(hr.getBody());
        if(resp.containsKey('done') && resp.get('done') == true) {
            if(resp.containsKey('records')) {
                List<Object> records = (List<Object>) resp.get('records');
                for(Object o : records) {
                    Map<String,Object> respRecord = (Map<String,Object>) o;
                    if(String.valueOf(respRecord.get('Id')) == jobId) return String.valueOf(respRecord.get('Status'));
                }
            }
        } else return 'pending';
        return 'unknown';
    }

    public static String createUpdateMetadata(String typeName,String fullName, Map<String, Object> fieldsToUpdate) {
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        if(typeName.indexOf('__mdt') > -1) typeName = typeName.split('__mdt')[0];
        if(typeName.indexOf('__c') > -1) typeName = typeName.split('__c')[0];
        customMetadata.fullName = typeName + '.' + fullName;
        customMetadata.label = fullName;
        for(String s : fieldsToUpdate.keySet()) {
            addFieldValue(customMetadata, s, fieldsToUpdate.get(s));
        }
        return deploy(customMetadata);
    }
    private static String deploy(Metadata.CustomMetadata customMetadata) {
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);
        MetadataHandler callback = new MetadataHandler();
        return Metadata.Operations.enqueueDeployment(mdContainer, callback);
    }
    private static void addFieldValue(Metadata.CustomMetadata customMetadata, String fieldName, Object fieldValue) {
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
        customField.field = fieldName;
        customField.value = fieldValue;
        customMetadata.values.add(customField);
    }
}