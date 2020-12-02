public class sObjectManager {
    public class sObjectManagerException extends Exception {}
    private static Map<String, Schema.SObjectType> globalDescribe;
    private static Map<String, Schema.DescribeSObjectResult> objectDescribe = new Map<String, Schema.DescribeSObjectResult>();
    private static Map<String, Map<String, Schema.DescribeFieldResult>> fieldsDescribe = new Map<String, Map<String, Schema.DescribeFieldResult>>();
    private static Map<String, Map<String, List<Schema.PicklistEntry>>> picklistVals = new Map<String, Map<String, List<Schema.PicklistEntry>>>();
    
    private static Map<String, Schema.SObjectType> gd() {
        if(globalDescribe == null) globalDescribe = Schema.getGlobalDescribe();
        return globalDescribe;
    }
    public static sObject initialize(String objName) {
        if(gd().containsKey(objName)) {
            return gd().get(objName).newSObject();
        }
        return null;
    }
    public static Schema.DescribeSObjectResult describe(String objName) {
        if(gd().containsKey(objName)) {
            if(!objectDescribe.containsKey(objName)) {
                objectDescribe.put(objName, gd().get(objName).getDescribe());
            }
            return objectDescribe.get(objName);
        }
        return null;
    }
    public static Set<String> getFieldsAsSet(String objName) {
        if(gd().containsKey(objName)) {
            Set<String> fields = new Set<String>();
            if(!fieldsDescribe.containsKey(objName)) fieldsDescribe.put(objName, new Map<String, Schema.DescribeFieldResult>());
            Map<String, Schema.sObjectField> fieldsMap = describe(objName).fields.getMap();
            for(String s : fieldsMap.keySet()) {
                if(!fieldsDescribe.get(objName).containsKey(s)) {
                    fieldsDescribe.get(objName).put(s, fieldsMap.get(s).getDescribe());
                }
                fields.add(fieldsDescribe.get(objName).get(s).getName());
            }
            return fields;
        }
        return null;
    }
    public static List<Schema.DescribeFieldResult> getFields(String objName) {
        if(gd().containsKey(objName)) {
            if(!fieldsDescribe.containsKey(objName)) {
                fieldsDescribe.put(objName, new Map<String, Schema.DescribeFieldResult>());
                Map<String, Schema.sObjectField> fieldsMap = describe(objName).fields.getMap();
                for(String s : fieldsMap.keySet()) {
                    if(!fieldsDescribe.get(objName).containsKey(s)) {
                        fieldsDescribe.get(objName).put(s, fieldsMap.get(s).getDescribe());
                    }
                }
            }
            return fieldsDescribe.get(objName).values();
        }
        return null;
    }
    public static List<Schema.PicklistEntry> getPicklistValues(String objName, String picklistAPI) {
        if(gd().containsKey(objName)) {
            if(!picklistVals.containsKey(objName)) picklistVals.put(objName, new Map<String, List<Schema.PicklistEntry>>());
            if(!picklistVals.get(objName).containsKey(picklistAPI)) {
                for(Schema.DescribeFieldResult dfr : getFields(objName)) {
                    if(dfr.getType() == Schema.DisplayType.PICKLIST) {
                        picklistVals.get(objName).put(picklistAPI, dfr.getPicklistValues());
                    }
                }
            }
            return picklistVals.get(objName).get(picklistAPI);
        }
        return null;
    }
    public static Set<Schema.DescribeFieldResult> getRequiredFields(String objName) {
        if(gd().containsKey(objName)) {
            getFields(objName);
            
            Set<Schema.DescribeFieldResult> fields = new Set<Schema.DescribeFieldResult>();
            for(Schema.DescribeFieldResult dfr : fieldsDescribe.get(objName).values()) {
                if(!dfr.isNillable() && dfr.isCreateable()) {
                    fields.add(dfr);
                }
            }
            return fields;
        }
        return null;
    }

    public static String createFullQuery(String objName) {
        return createFullQuery(objName, true);
    }
    public static String createFullQuery(String objName, Boolean accessibleOnly) {
        if(gd().containsKey(objName)) {
            getFields(objName);
            Set<String> fields = new Set<String>();
            for(Schema.DescribeFieldResult dfr : fieldsDescribe.get(objName).values()) {
                if(accessibleOnly) {
                    if(dfr.isAccessible()) fields.add(dfr.getName());
                } else {
                    if(dfr.isAccessible()) fields.add(dfr.getName());
                }
            }
            
            return 'SELECT ' + String.join(new List<String>(fields), ',') + ' FROM ' + objName;
        }
        return null;
    }
}