# Batch Handler

### 1. Batch Handler - Implementation
-The batch handler framework offers extendable code that allows easy creation of batch jobs that can run recurring in intervals by the minute. The framework also allows you to control the settings via custom metadata. 

### 2. Batch Handler - Configuring metadata
-Create a record on the `Batch Handler Setting` metadata type and take note of the `Developer Name`. Set it to active, and set the batch size and the intervals on ther respective fields.


### 3. Batch Handler - Sample Code
-To run a batch job as part of the framework, you will need to create a class whose class name is equal to your metadata's developer name. It needs to extend the `BatchHandler` class and implement the `Schedulable` class. Sample below:

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
to run this class, you would call it like how you normally call a batch job, by using the `Database.executeBatch` class and method. The framework will then check the metadata record, and rerun it if it is marked as recurring, and with the settings you have identified.
