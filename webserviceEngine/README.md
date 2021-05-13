# Web Service Engine

Contents:
1. [Notes](#notes) 
2. [Usage Instructions](#usage-instructions) \
 I. [Setting up the Metadata](#setting-up-the-metadata) \
 II. [Coding the Callout](#coding-the-callout) \
 III. [Authentication types](#authentication-types) \
 IV. [Callout Logs and retry](#callout-logs-and-retry) \
 V. [Testing your Code](#testing-your-code) 

## Notes

The Webservice engine stores inbound callout data in a custom metadata and uses a core Apex class to execute the setup of the needed variables to build the Webservice callout setup for you. When using this framework, the only thing the developer will need to focus on would be the return data and the logic to run when accessing the web service.

## Usage Instructions
### I. Setting up the Metadata
1. Open the `Webservice Unit` metadata and create a new record
2. Provide a label and a unique name - you will be using the Unique name later on
3. Set it to `Active` to enable usage of the record you created
4. Add a `Group` so you can sort your webservices easily
5. Leave the `Implementation` field for now. We will populate this after we create the APEX class
6. Save and take note of your Metadata Developer name as this will be attached to the endpoint of your webservice

### II. Coding the Webservice
1. Create an APEX class extending the `WebserviceEngine.WebserviceUnit` class. It can be a base class, or an inner class
```java
public class SampleWebService extends WebserviceEngine.WebserviceUnit {
  //code here
}
```
2. Copy the class name, in this case `SampleWebservice` and paste it on the `Implementation` field on your Metadata record, If it is an inner class, add the whole reference to the class name. For the sample below, you will populate the `Implementation` with `SampleWebService.SampleInnerClassWs`:
```java
public class SampleWebService {
  public class SampleInnerClassWs extends WebserviceEngine.WebserviceUnit {
    //code here
  }
}
```
3. Override the method that you wish to implement for your webservice, the overrideable methods are the following:
```java
  global virtual void doGet() {}
  global virtual void doPost() {}
  global virtual void doDelete() {}
  global virtual void doPut() {}
  global virtual void doPatch() {}
```
4. Below is a sample class implementing a GET webservice
```java
public class GetAccount extends WebserviceEngine.WebserviceUnit {
  public override void doPost() {
    List<Account> newList = [SELECT Id, Name FROM Account WHERE Name = 'SampleWs'];
    this.setBody(JSON.serialize(newList));
  }
}
```

### III. Accessing the callout
-Accessing the callout will be the same as accessing a normally built Webservice. You will still need to create the connected app, take the Client ID and Secret, and use the Login to request for a token. The actual callout will now use the URL `/services/apexrest/wse/<Your metadata developer name>/`.

### IV. Available Methods
#### Map<String,String> getRequestParams()
You can use the `Map<String,String> getRequestParams()` method on your class to get the request parameters. A callout with the url `/services/apexrest/wse/SampleWs?param1=John&param2=Smith`, the map that this method returns will look like this:
|Key |Value|
--- | ---
|param1|John|
|param2|Smith|

#### String getRequestBody()
This method will simply return the String representation of the request body


#### void setBody(Object body)
This method allows you to set the return body of the callout, and will return a code 200 if the code is not set

#### void setError(Integer code, String message)
This method allows you to return an error message and an error code in the case of an error.

#### void setContentType(String contentType)
This method allows you to set the Content type for the webservice return


### V. Sample code
-The code below shows a sample implementation. This runs a query on the Contact object, and uses a parameter passed from the URL to run the search on the Lastname field. An error is returned if the Contact is not found
```java
public class findContact extends WebserviceEngine.WebserviceUnit {
  public override void doGet() {
    Map<String,String> requestParams = this.getRequestParams();
    if(requestParams.containsKey('lastname')) {
      String ln = requestParams.get('lastname');
      List<Contact> contactSearch = [SELECT Id, FirstName, LastName FROM Contact WHERE LastName = :ln LIMIT 1];
      if(contactSearch.isEmpty()) {
        this.setError(404,'Contact not found');
      } else {
        this.setBody(JSON.serialize(contactSearch[0]));
      }
    } else {
      this.setError(403,'Last name not found in query');
    }
  }
}
```
