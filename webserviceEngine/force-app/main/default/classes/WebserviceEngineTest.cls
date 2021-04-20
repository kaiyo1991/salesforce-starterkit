@isTest
public class WebserviceEngineTest {
    public class WebserviceUnitTest extends WebserviceEngine.WebserviceUnit {}
    
    @isTest
    public static void testWsu() {
        WebserviceUnitTest wsu = new WebserviceUnitTest();
        RestRequest req = new RestRequest();
        req.requestURI = '/wse/WebserviceUnitTest';
        req.httpMethod = 'PUT';
        req.requestBody =  Blob.valueof('{"test":"test"}');
        RestContext.request = req;

        wsu.initialize(req, new Map<String,String>());
        
        Test.startTest();
        wsu.getRequestBody();
        wsu.getRequestParams();
        wsu.setError(404, 'Not Found');
        wsu.setBody('{"test":"test"}');
        wsu.setContentType('application/json');
        Test.stopTest();
    }
    @isTest
    public static void testGett() {
        WebserviceUnitTest wsut = new WebserviceUnitTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/wse/WebserviceUnitTest';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        WebserviceEngine.doGet();
        Test.stopTest();
    }
    @isTest
    public static void testPost() {
        WebserviceUnitTest wsut = new WebserviceUnitTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/wse/WebserviceUnitTest';
        req.httpMethod = 'POST';
        req.requestBody =  Blob.valueof('{"test":"test"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        WebserviceEngine.doPost();
        Test.stopTest();
    }
    @isTest
    public static void testPut() {
        WebserviceUnitTest wsut = new WebserviceUnitTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/wse/WebserviceUnitTest';
        req.httpMethod = 'PUT';
        req.requestBody =  Blob.valueof('{"test":"test"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        WebserviceEngine.doPut();
        Test.stopTest();
    }
    @isTest
    public static void testDelete() {
        WebserviceUnitTest wsut = new WebserviceUnitTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/wse/WebserviceUnitTest';
        req.httpMethod = 'DELETE';
        req.requestBody =  Blob.valueof('{"test":"test"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        WebserviceEngine.doDelete();
        Test.stopTest();
    }
    @isTest
    public static void testPatch() {
        WebserviceUnitTest wsut = new WebserviceUnitTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/wse/WebserviceUnitTest';
        req.httpMethod = 'PATCH';
        req.requestBody =  Blob.valueof('{"test":"test"}');
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        WebserviceEngine.doPatch();
        Test.stopTest();
    }
    
    @isTest
    public static void testNotFound() {
        WebserviceUnitTest wsut = new WebserviceUnitTest();
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/wse/test';
        req.httpMethod = 'GET';
        
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        WebserviceEngine.doGet();
        Test.stopTest();
    }
    
    @isTest
    public static void metadataTest() {
        Map<String,Object> fieldsToAdd = new Map<String,Object>();
        fieldsToAdd.put('Active__c',true);
        MetadataHandler.createUpdateMetadata('WebserviceUnit__mdt','WebserviceUnitTest',fieldsToAdd);
    }
}