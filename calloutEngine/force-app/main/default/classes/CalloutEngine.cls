/***********************
 * Class Name: CalloutEngine
 * Author: Kevin Ibalio
 * Purpose: 
************************/

public class CalloutEngine {
    private String calloutKey;
    private String calloutEndpoint;
    private String calloutBody;
    private String calloutMethod;
    private Boolean oAuthPrepared = false;
    private Map<String,String> calloutEndpointParams = new Map<String,String>();
    private Map<String,String> calloutHeaders = new Map<String,String>();
	private CalloutLog__c retrySource;
    private CalloutEngineSetting__mdt setting;
    private HttpRequest callRequest;
    private HttpResponse callResponse;
    
    //Static methods
    public static HttpResponse call(String endpoint, String method, Map<String, String> headers, String body) {
        Http h = new Http();
        HttpRequest request = new HttpRequest();

        if(headers != null) {
            for(String key : headers.keySet()) {
                request.setHeader(key, headers.get(key));
            }
        }
        request.setEndpoint(endPoint);
        request.setMethod(method); 
        if(body != null) request.setBody(body);
        
        HttpResponse response = h.send(request);
        return response;
    }
    
    //Class constructors
    public CalloutEngine(String key) {
        if(key == null || key == '') throw new CalloutEngineException(INVALID_KEY);
        this.calloutKey = key;
        sObject s = MetadataHandler.getData('CalloutEngineSetting__mdt',key);
        if(s == null) {
            throw new CalloutEngineException(key + ' ' + SETTING_NOT_FOUND);
        } else {
            CalloutEngineSetting__mdt chs = (CalloutEngineSetting__mdt) s;
            this.setting = chs;
            this.parseSetting();
        }
    }
    public CalloutEngine(CalloutLog__c retrySrc) {
        this.retrySource = retrySrc;
        if(this.retrySource.CalloutSource__c == null) throw new CalloutEngineException(INVALID_KEY);
        this.calloutKey = this.retrySource.CalloutSource__c;
        sObject s = MetadataHandler.getData('CalloutEngineSetting__mdt',this.calloutKey);
        if(s == null) {
            throw new CalloutEngineException(this.calloutKey + ' ' + SETTING_NOT_FOUND);
        } else {
            CalloutEngineSetting__mdt chs = (CalloutEngineSetting__mdt) s;
            this.setting = chs;
            this.parseSettingFromLog();
        }
    }
    
    //Private methods
    private void parseSetting() {
        this.calloutEndpoint = this.setting.Endpoint__c;
        this.calloutMethod = this.setting.Method__c != null ? this.setting.Method__c : 'GET';
 
        if(this.setting.DefaultParameters__c != null) {
            Map<String, Object> paramsParsed = (Map<String, Object>) JSON.deserializeUntyped(this.setting.DefaultParameters__c);
            for(String s : paramsParsed.keySet()) {
                this.calloutEndpointParams.put(s, String.valueOf(paramsParsed.get(s)));
            }
        }
        
        if(this.setting.DefaultHeaders__c != null) {
            Map<String, Object> paramsParsed = (Map<String, Object>) JSON.deserializeUntyped(this.setting.DefaultHeaders__c);
            for(String s : paramsParsed.keySet()) {
                this.calloutHeaders.put(s, String.valueOf(paramsParsed.get(s)));
            }
        }
    }
    private void parseSettingFromLog() {
        this.calloutEndpoint = this.retrySource.Endpoint__c;
        this.calloutMethod = this.retrySource.RequestMethod__c != null ? this.retrySource.RequestMethod__c : 'GET';
        this.calloutEndpointParams = new Map<String,String>();
        if(this.retrySource.RequestHeadersJson__c != null) {
            Map<String, Object> paramsParsed = (Map<String, Object>) JSON.deserializeUntyped(this.retrySource.RequestHeadersJson__c);
            for(String s : paramsParsed.keySet()) this.calloutHeaders.put(s, String.valueOf(paramsParsed.get(s)));
        }
        this.calloutBody = this.retrySource.RequestBody__c;
    }
    private void rebuildEndpoint() {
        if(this.setting.CalloutType__c == 'Named Credential') {
            this.calloutEndpoint = 'callout:' + this.setting.NamedCredentialName__c + (this.setting.NamedCredentialPath__c != null ? this.setting.NamedCredentialPath__c : '');
        } else {
            List<String> urlParams = new List<String>();
            for(String s : this.calloutEndpointParams.keySet()) {
                String finder = '<' + s + '>';
                if(this.calloutEndpoint.indexOf(finder) > -1) this.calloutEndpoint = this.calloutEndpoint.replaceAll(finder, this.calloutEndpointParams.get(s));
                else urlParams.add(s + '=' + this.calloutEndpointParams.get(s));
            }
            if(!urlParams.isEmpty()) this.calloutEndpoint += (this.calloutEndpoint.indexOf('?') > -1 ? '&' : '?') + String.join(urlParams, '&');
        }
    }
    private void addAuth(HttpRequest hr) {
        switch on this.setting.AuthenticationType__c {
            when 'Simple' { this.handleSimple(); }
            when 'API Key' { this.handleApiKey(); }
            when 'Basic' { this.handleBasic(); }
            when 'Bearer' { this.handleBearer(); }
            when 'OAuth' { this.handleOAuth(); }
            when else { /* do nothing */ }
        }
    }
    private void handleSimple() {
        this.calloutHeaders.put('Authorization', this.setting.SimpleToken__c);
    }
    private void handleApiKey() {
        switch on this.setting.APIKeyTokenPlacement__c {
            when 'Endpoint' {
                this.calloutEndpointParams.put('api_key', this.setting.APIKeyToken__c);
            }
            when 'Header' {
                this.calloutHeaders.put('X-API-Key', this.setting.APIKeyToken__c);
            }
            when 'Both' {
                this.calloutEndpointParams.put('api_key', this.setting.APIKeyToken__c);
                this.calloutHeaders.put('X-API-Key', this.setting.APIKeyToken__c);
            }
            when null {
                this.calloutHeaders.put('X-API-Key', this.setting.APIKeyToken__c);
            }
        }
    }
    private void handleBasic() {
        if(this.setting.BasicToken__c == null) {
            Blob headerValue = Blob.valueOf(this.setting.BasicUsername__c + ':' + this.setting.BasicPassword__c);
            this.setting.BasicToken__c = EncodingUtil.base64Encode(headerValue);
        }
        this.calloutHeaders.put('Authorization', 'Basic ' + this.setting.BasicToken__c);
    }
    private void handleBearer() {
        this.calloutHeaders.put('Authorization', 'Bearer ' + this.setting.BearerToken__c);
    }
    private void handleOAuth() {
        if(!this.oAuthPrepared) throw new CalloutEngineException('For OAuth callouts, please call the [HttpResponse prepareOAuth()] method first');
    }
    private CalloutLog__c createLog(Boolean isSuccess, Boolean retry, Integer retrycount) {
        return new CalloutLog__c(
        	Status__c = isSuccess ? 'Success' : 'Failed',
            Endpoint__c = this.calloutEndpoint,
            RequestBody__c = this.calloutBody,
            RequestHeadersJson__c = JSON.serialize(this.calloutHeaders),
            RequestMethod__c = this.calloutMethod,
            RetryCount__c = retryCount,
            RetrySource__c = this.retrySource == null? null : this.retrySource.Id,
            CalloutSource__c = this.calloutKey,
            ResponseHandler__c = this.setting.RetryResponseHandler__c,
            ResponseCode__c = String.valueOf(this.callResponse.getStatusCode()),
            ResponseBody__c = this.callResponse.getBody(),
            Retry__c = retry
        );
    }
    
    //public methods
    public void setBody(String calloutBody) {
        this.calloutBody = calloutBody;
    }
    public void setEndpointParams(Map<String,String> endpointValues) {
        for(String s : endpointValues.keySet()) this.calloutEndpointParams.put(s, endpointValues.get(s));
    }
    public void setEndpointParam(String key,String value) {
        this.calloutEndpointParams.put(key, value);
    }
    public void setHeaders(Map<String,String> headerValues) {
        for(String s : headerValues.keySet()) this.calloutHeaders.put(s, headerValues.get(s));
    }
    public void setHeader(String key, String value) {
        this.calloutHeaders.put(key, value);
    }
    public void overrideHeader(Map<String, String> headers) {
        for(String s : headers.keySet()) this.calloutHeaders.put(s, headers.get(s));
    }
    public HttpResponse prepareOAuth() {
        this.oAuthPrepared = true;
        return call(this.setting.OAuthEndpoint__c,
            this.setting.OAuthMethod__c,
            new Map<String,String>(),null);
    }
    public Object call(String body) {
        this.setBody(body);
        return this.call();
    }
    public Object call() {
        Http h = new Http();
        HttpRequest hr = new HttpRequest();
        
        this.addAuth(hr);
        if(this.retrySource == null) this.rebuildEndpoint();
        
        hr.setEndpoint(this.calloutEndpoint);
        hr.setMethod(this.calloutMethod);
        
        if(this.calloutBody != null) hr.setBody(this.calloutBody);
        for(String s : this.calloutHeaders.keySet()) hr.setHeader(s, this.calloutHeaders.get(s));
        
        HttpResponse response = h.send(hr);
        this.callRequest = hr;
        this.callResponse = response;
        return response.getBody();
    }
    public HttpResponse getResponse() {
        return this.callResponse;
    }
    public void markFailed() {
        this.markFailed(false);
    }
    public void markFailed(Boolean queueLogCreate) {
        if(this.setting.RecordLogging__c) {
            if(this.setting.RetryCount__c == null) this.setting.RetryCount__c = 1; 
            Integer retryCount = this.retrySource == null ? 0 : (Integer.valueOf(this.retrySource.RetryCount__c) + 1);
            Boolean retry = this.setting.RetryOnFail__c && this.setting.RetryCount__c >= retryCount;
            CalloutLog__c cl = this.createLog(false, retry, retryCount);
            
            if(queueLogCreate) {
                System.enqueueJob(new CalloutLogCreate(cl));
            } else {
                insert cl;
                if(retry) System.enqueueJob(new CalloutRetryHandler(cl));
            }
            
        }
    }
    public void logSuccess() {
        Integer retryCount = this.retrySource == null ? 0 : (Integer.valueOf(this.retrySource.RetryCount__c) + 1);
        insert this.createLog(true,false,null);
    }

    //Inner Classes and Interfaces
    public class CalloutLogCreate implements Queueable {
        public CalloutLog__c log;
        public Boolean retry = false;
        public CalloutLogCreate(CalloutLog__c log) {
            this.log = log;
        }
        public void execute(QueueableContext context) {
            insert this.log;
            if(this.log.Retry__c) System.enqueueJob(new CalloutRetryHandler(this.log));
        }
    }
    public class CalloutRetryHandler implements Queueable, Database.AllowsCallouts {
        public CalloutLog__c log;
        public CalloutRetryHandler(CalloutLog__c log) {
            this.log = log;
        }
        public void execute(QueueableContext context) {
            Type t = Type.forName(this.log.ResponseHandler__c);
            CalloutResponseHandler crh = (CalloutResponseHandler) t.newInstance();
            CalloutEngine ch = new CalloutEngine(this.log);
            ch.call();
            crh.handleResponse(ch);
        }
    }
    private class CalloutEngineException extends Exception {}
    public interface CalloutResponseHandler {
        Map<String,Object> handleResponse(CalloutEngine ch);
    }
    
    //Messaging attributes
    private static final String SETTING_NOT_FOUND = 'callout setting not found in the Custom Metadata';
    private static final String INVALID_KEY = 'The callout key provided is invalid';
}