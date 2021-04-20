@isTest
public class sObjectManagerTest {
	@isTest
    public static void testAll() {
        Test.startTest();
        Account a = (Account) sObjectManager.initialize('Account');
        sObjectManager.describe('Account');
        sObjectManager.getFieldsAsSet('Account');
        sObjectManager.getFields('Account');
        sObjectManager.getPicklistValues('Account','CleanStatus');
        sObjectManager.getRequiredFields('Account');
        sObjectManager.createFullQuery('Account');
        sObjectManager.createFullQuery('Account',true);
        Test.stopTest();
    }
    @isTest
    public static void testNonPresentObject() {
        Test.startTest();
        sObjectManager.getFields('Account');
        Test.stopTest();
    }
}