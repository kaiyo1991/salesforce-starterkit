# Trigger Handler Framework

### 1. Introduction

The Trigger Handler class is an extendable class that handles the setup code that you have to do when setting up a trigger. It allows for overriding of methods to handle the trigger event currently being executed, creates a breadcrumb logging mechanism to allow developers to easily trace the code, and allows for logging of apex limits and usage per event to give the developers an idea of how their trigger event is performing. It also creates a metadata record for every class extending the `TriggerHandler` class which allows users to easily disable trigger logic per given event.

### 2. Implementation

To be able to use the TriggerHandler framework, you need to create an APEX class that extends the `TriggerHandler` class. The class name you create should have a descriptive name since that name will be used as the Custom metadata record identifier. An example of a relevant name is `AccountTriggerHandler`. This name is effective since it has the sObject name that the trigger gets attached to.

```apex
public class <className> extends TriggerHandler {
}
```

You will be able to add logic to your trigger events by overriding specific methods from the `TriggerHandler` class. The example below runs a field update to a custom rating field based on Scoring fiends. There are 4 data set variables that are inherited from the `TriggerHandler` class namely `newList`, `oldList`,`newMap`, and `oldMap` which can be directly used within the override methods. The overrideable methods are `void beforeInsert()`, `void beforeUpdate()`, `void beforeDelete()`, `void afterInsert()`, `void afterUpdate()`, `void afterDelete()`, `void afterUndelete()`,

```apex
public class AccountTriggerHandler extends TriggerHandler {
    public override void beforeInsert() {
        for(Account a : newList) {
	  //you may directly loop the newList attribute and add your logic
          System.debug(a);
          //YOUR CODE HERE
        }
    }
    public override void afterInsert() {
    }
}
```

### 3. Sample Code

Sample trigger implementation on the account object. Adding all events is optional - and while it is recommended to add only the events that your logic will handle, adding all events reduces code deployment effort if a new event needs to be added to production.
```java
trigger AccountTrigger on Account (before insert,after insert,before update,after update,before delete,after delete,after undelete) {
	TriggerHandler.initialize('AccountTriggerHandler');
}
```

Below is the class that implements the `TriggerHandler` class. Note that the name `AccountTriggerHandler` is the same as the String passed on the trigger implementation example above. This will also be used as the Custom Metadata record name which will control the trigger flow.
```apex
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

### 4. Updating the metadata

The `Trigger Handler Settings` Custom metadata type controls the trigger flow when using the `TriggerHandler` framework. Checkboxes are available per event which you can disable by setting the value to true. If a record does not exist for a specific trigger extension, a new record will be created on the first execution which defaults to globally active and logging enabled.


### 5. Roadmap
-Test class coverage for base classes

-Multi-catch exception logging mechanism through Platform events

-Command Center app - a better UI interface hosted under Command Center to allow updating of metadata records and testing of trigger logic.
