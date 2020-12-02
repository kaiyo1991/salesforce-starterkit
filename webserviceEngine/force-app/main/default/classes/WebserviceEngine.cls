@RestResource(urlMapping='/wse/*')
global class WebserviceEngine {
    private static String unitKey;
    private static RestRequest req = RestContext.request;
    private static RestResponse resp = RestContext.response;
    private static WebserviceUnit__mdt setting;
    private static WebserviceUnit wsu;
    private static Map<String,String> params = new Map<String, String>();
    
    private static void findMeta() {
        List<String> urlSplit = req.requestURI.split('/');
        if(urlSplit.size() <= 2) {
            //throw error
			setNotImplemented(); 
        } else {
            WebserviceEngine.unitKey = urlSplit[2];
            sObject s = MetadataHandler.getData('WebserviceUnit__mdt',unitKey);
            WebserviceEngine.setting = (WebserviceUnit__mdt) s;
            if(WebserviceEngine.setting != null && WebserviceEngine.setting.Implementation__c != null) {
                Type t = Type.forName(WebserviceEngine.setting.Implementation__c);
                WebserviceEngine.wsu = (WebserviceUnit) t.newInstance();
            }
        }
    }
    private static void getParams() {
        params = req.params;
    }
    private static void setNotFound() {
        resp.statusCode = 404;
        resp.responseBody = Blob.valueOf('[WSE] Service is inactive or not found');
    }
    private static void setNotImplemented() {
        resp.statusCode = 501;
        resp.responseBody = Blob.valueOf('[WSE] Service Implementation is missing');
    }
    private static void run() {
        findMeta();
        getParams();
        if(WebserviceEngine.wsu == null) {
            setNotImplemented();
        } else if(WebserviceEngine.setting != null && WebserviceEngine.setting.Active__c) {
            switch on req.httpMethod {
                when 'GET' { wsu.doGet(); }
                when 'POST' { wsu.doPost(); }
                when 'DELETE' { wsu.doDelete(); }
                when 'PATCH' { wsu.doPatch(); }
                when 'PUT' { wsu.doPut(); }
                when 'HEAD' { wsu.doHead(); }
                when else { /* do nothing */ }
            }
            wsu.getContentType(resp);
            resp.responseBody = wsu.getBody();
        } else {
            setNotFound();
        }
    }
    
	@HttpGet
    global static void doGet() { run(); }
    
	@HttpPost
    global static void doPost() { run(); }
    
	@HttpDelete
    global static void doDelete() { run(); }
    
	@HttpPut
    global static void doPut() { run(); }
    
	@HttpPatch
    global static void doPatch() { run(); }
    
    
    global virtual class WebserviceUnit {
        private String body;
        private String contentType;
        global void setBody(Object body) {
            this.body = String.valueOf(body);
        }
        global Blob getBody() {
            return Blob.valueOf(this.body);
        }
        global void getContentType(RestResponse resp) {
            resp.addHeader('Content-Type', this.contentType);
        }
        global void setContentType(String contentType) {
            this.contentType = contentType;
        }
        global virtual void doGet() {}
        global virtual void doPost() {}
        global virtual void doDelete() {}
        global virtual void doPut() {}
        global virtual void doPatch() {}
        global virtual void doHead() {}
    }
}