@isTest
public class CalloutEngineTest {
    @isTest
    public static void testBasic() {
        CalloutEngine calloutRun = new CalloutEngine('TEST_Basic');
        calloutRun.setEndpointParam('test1','asd');
        calloutRun.setEndpointParam('test2','asd');
        calloutRun.setMock('{"test":"test"}');
        
        Test.startTest();
        calloutRun.call();
        calloutRun.logSuccess();
        calloutRun.markFailed();
        Test.stopTest();
        
    }
    
    @isTest
    public static void testSimple() {
        CalloutEngine calloutRun = new CalloutEngine('TEST_Simple');
        Map<String,String> epParams = new Map<String,String>();
        epParams.put('test1','asd');
        epParams.put('test2','asd');
        calloutRun.setEndpointParams(epParams);
        calloutRun.setMock(200,'{"test":"test"}');
        
        Test.startTest();
        calloutRun.call();
        Test.stopTest();
    }
    
    @isTest
    public static void testBearer() {
        CalloutEngine calloutRun = new CalloutEngine('TEST_Bearer');
        Map<String,String> headParams = new Map<String,String>();
        headParams.put('test1','asd');
        calloutRun.setHeaders(headParams);
        calloutRun.setHeader('test2','asd');
        calloutRun.setBody('{"test":"test"}');
        calloutRun.setMock(200,'{"test":"test"}');
        
        Test.startTest();
        calloutRun.call();
        Test.stopTest();
    }
    
    @isTest
    public static void testAPIKey() {
        CalloutEngine calloutRun = new CalloutEngine('TEST_APIKey');
        calloutRun.setMock(200,'{"test":"test"}');
        
        Test.startTest();
        calloutRun.call();
        Test.stopTest();
    }
    @isTest
    public static void testOAuth() {
        CalloutEngine calloutRun = new CalloutEngine('TEST_OAuth');
        Map<String,String> headParams = new Map<String,String>();
        headParams.put('test1','asd');
        calloutRun.setHeaders(headParams);
        calloutRun.setHeader('test2','asd');
        calloutRun.setBody('{"test":"test"}');
        calloutRun.setMockOAuth('{"access_token":"12345"}');
        calloutRun.setMock(200,'{"test":"test"}');
        
        Test.startTest();
        calloutRun.call('{"test":"test"}');
        Test.stopTest();
    }
    
    @isTest
    public static void testBaseCall() {
        Test.setMock(HttpCalloutMock.class, new CalloutEngine.CalloutEngineMock('{"a":"a"}',200));
        Test.startTest();
        CalloutEngine.call('www.test.com','GET',new Map<String,String>(),'{"a":"a"}');
        Test.stopTest();
    }
    @isTest
    public static void metadataTest() {
        Map<String,Object> fieldsToAdd = new Map<String,Object>();
        fieldsToAdd.put('Method__c','PUT');
        MetadataHandler.createUpdateMetadata('CalloutEngineSetting__mdt','TEST_OAuth',fieldsToAdd);
    }
}