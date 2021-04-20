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
        if(Test.isRunningTest()) {
            Metadata.DeployResult result = new Metadata.DeployResult();
            result.status = Metadata.DeployStatus.Succeeded;
            Metadata.DeployCallbackContext context = new Metadata.DeployCallbackContext();
            callback.handleResult(result, context);
            return null;
        } else {
        	return Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }
    }
    private static void addFieldValue(Metadata.CustomMetadata customMetadata, String fieldName, Object fieldValue) {
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
        customField.field = fieldName;
        customField.value = fieldValue;
        customMetadata.values.add(customField);
    }
	
}