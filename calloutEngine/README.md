# Callout Engine

## Notes

The Callout engine stores outbound callout data in a custom metadata and uses a core Apex class to execute the setup of the needed variables and does the callout for you. Instead of coding the callout setup, the developer will now only need to setup the record on the `CalloutEngineSetting__mdt` custom metadata and setup the body and any dynamic details on the callout.

## Usage Instructions
### Setting up the Metadata
1. Open the `Callout Engine Setting` metadata and create a new record
2. Provide a label and a unique name - you will be using the Unique name later on
3. The callout type will be defaulted to `Standard Apex`. Named credentials are currently not supported but will be supported in the future.
4. Provide the endpoint and the method. You may use brackets (<>) to annotate variable values in your endpoint. A URL with dynamic variables will look like this `https://www.test.com/<param1>/<param2>` and can be populated on your code.
5. Provide your Auth type and populate the fields on the section pertaining to your selected Auth type. Each Auth type section will be discussed further below.
6. If you have a default callout header, you may populate the `Default Headers` field with a JSON formatted text. Sample below
 ```javascript
 {
  "Content-Type":"application/json"
 }
 ```
6. Save and use the Metadata developername on your code to use a specific record.

### Coding the Callout
1. Create an instance of the class `CalloutEngine`, pass the Metadata developername as the constructor parameter.
```java
CalloutEngine test = new CalloutEngine('sample_metadata_developername');
```
2. If you have any endpoint parameter e.g. (Endpoint provided is `https://www.test.com/<param1>/<param2>/`), you may use the method `setEndpointParam` to populate this value.
```java
CalloutEngine test = new CalloutEngine('sample_metadata_developername');
//Sample endpoint is https://www.test.com/<param1>/<param2>
//Code below will populate the param1
test.setEndpointParam('param1','sampleurlparameter');
//Another to populate param2
test.setEndpointParam('param2','moreurlparameters');
//which will make our final endpoint https://www.test.com/sampleurlparameter/moreurlparameters

//Adding a non existing merge text will add it as a parameter url
test.setEndpointParam('newUrlparam','newurlparameter');
//this would make final endpoint as https://www.test.com/sampleurlparameter/moreurlparameters?newUrlparam=newurlparameter
```
3. Alternatively, you may use the `setEndpointParams` method and pass a `Map<String,String>` to populate all parameters in one go.
4. Callout headers may be added using the `setHeader(String key, String value)` or the `setHeaders(Map<String,String> headerValues)` methods.
5. Callout body may be set using the `setBody(String calloutBody)` method.
6. Use the `call()` method to run the callout, or use the `call(String body)` to set the callout body, and run the callout in one method.
7. After running the call method, it will be returning an `Object` type variable which is the callout response's body.
8. You may access the full `HttpResponse` of the callout by using the `getResponse()` method.
9. Below is a sample code running a full callout with URL parameters and Callout headers
```java
//setup the callout payload
Account a = new Account(
  Name = 'SampleAccount',
  AnnualRevenue = 100000
);

//Create the engine instance
CalloutEngine test = new CalloutEngine('sample_callout');
//Set the header
test.setHeader('Content-Type','application/json');
//Set the body and serialize it as JSON
test.setBody(JSON.serialize(a));
//Run the callout
test.call();
HttpResponse resp = test.getResponse();
```

### Authentication types
#### Simple
Simple authentications is basically adding the `Authorization` header to the callout. The field value from `Simple: Token` will be used. 
|Header Key |Header Value  |
--- | ---
|Authorization|(value from Simple: Token field)|

#### Basic
Basic authentications is using a Username and Password to generate a key. The field value from `Basic: Token` can be populated if you already have the key, otherwise, the `Basic:Username` and `Basic:Password` will be used to generate the `Authorization` Header 
|Header Key |Header Value  |
--- | ---
|Authorization|Basic (value from Basic: Token field or generated from Username and Password)|

#### Bearer
Bearer Authentication is similar to Simple, but the token is typically generated as part of an OAuth flow.
|Header Key |Header Value  |
--- | ---
|Authorization|Bearer (value from Basic: Token field or generated from Username and Password)|

#### OAuth








