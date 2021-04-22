# Callout Engine

## Notes

The Callout engine stores outbound callout data in a custom metadata and uses a core Apex class to execute the setup of the needed variables and does the callout for you. Instead of coding the callout setup, the developer will now only need to setup the record on the `CalloutEngineSetting__mdt` custom metadata and setup the body and any dynamic details on the callout.

## Usage Instructions
### Setting up the Metadata
1. Open the `Callout Engine Setting` metadata and create a new record
2. Provide a label and a unique name - you will be using the Unique name later on
3. Provide the endpoint and the method. You may use brackets (<>) to annotate variable values in your endpoint. A URL with dynamic variables will look like this `https://www.test.com/<param1>/<param2>` and can be populated on your code.
4. Provide your Auth type and populate the fields on the section pertaining to your selected Auth type. Each Auth type section will be discussed further below.
5. Save and use the Metadata developername on your code to use a specific record.

###Coding the Callout
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












---------------------------------------------------------

# Salesforce Project Starter kit

## Trigger Handler

### 1. Trigger Handler - Introduction

The Trigger Handler class is an extendable class that handles the setup code that you have to do when setting up a trigger. It allows for overriding of methods to handle the trigger event currently being executed, creates a breadcrumb logging mechanism to allow developers to easily trace the code, and allows for logging of apex limits and usage per event to give the developers an idea of how their trigger event is performing. It also creates a metadata record for every class extending the `TriggerHandler` class which allows users to easily disable trigger logic per given event.

### 2. Trigger Handler - Implementation

To be able to use the TriggerHandler framework, you need to create an APEX class that extends the `TriggerHandler` class

```java
public class <className> extends TriggerHandler {
}
```

You will be able to add logic to your trigger events by overriding specific methods from the `TriggerHandler` class. The example below runs a field update to a custom rating field based on Scoring fiends. There are 4 data set variables that are inherited from the `TriggerHandler` class namely `newList`, `oldList`,`newMap`, and `oldMap` which can be directly used within the override methods.

```java
public class AccountTriggerHandler extends TriggerHandler {
  public override void beforeInsert() {
    for(Account a : newList) {
        if(a.Score__c > 4) a.Rating__c = 'Green';
        else if(a.Score__c <= 4 && a.Score__c > 2) a.Rating__c = 'Orange';
        else  a.Rating__c = 'Red';
    }
  }
}
```

### 3. Trigger Handler - Sample Code
```java
public class AccountTriggerHandler extends TriggerHandler {
    public override void beforeInsert() {
        for(Account a : newList) {
          System.debug(a);
          //YOUR CODE HERE
        }
    }
    public override void afterInsert() {
    }
}
```

### 4. Trigger Handler - Updating the metadata



## Batch Handler

### 1. Batch Handler - Implementation

1.
### 2. Batch Handler - Configuring metadata


### 3. Batch Handler - Sample Code
```java
public class AccountBatch extends BatchHandler implements Schedulable {
    public AccountBatch() {
        this.setQuery('SELECT Id FROM Account LIMIT 1');
        this.setScheduleMetadataKey('AccountBatch');
    }

    public override Database.Batchable<sObject> initialize() {
        return new AccountBatch();
    }

    public override void runBatch(List<SObject> scope) {
        List<Account> acctList = (List<Account>) scope;
        for(Account a : acctList) {
            System.debug(a);
        }
    }
}
```



## Callout Handler

### 1. Callout Handler - Implementation
1.

### 2. Callout Handler - Configuring Metadata

### 3. Callout Handler - Sample Code

```java
CalloutHandler zipCodeDistance = new CalloutHandler('ZipCodeDistance');
zipCodeDistance.setEndpointParam('zip_code1','32007');
zipCodeDistance.setEndpointParam('zip_code2','32040');
zipCodeDistance.setEndpointParam('weirdParam','12314123');
zipCodeDistance.call();
```
