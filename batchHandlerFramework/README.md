# Batch Handler

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
