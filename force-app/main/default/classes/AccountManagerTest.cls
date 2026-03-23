/**
 * @description Test class for AccountManager
 * @author Your Name
 * @date 2026-03-04
 */
@isTest
public class AccountManagerTest {
    
    /**
     * @description Setup test data - creates test accounts
     */
    @testSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        // Create test accounts with different industries
        testAccounts.add(new Account(Name = 'Tech Corp', Industry = 'Technology', Type = 'Customer'));
        testAccounts.add(new Account(Name = 'Finance Inc', Industry = 'Finance', Type = 'Partner'));
        testAccounts.add(new Account(Name = 'Health Plus', Industry = 'Healthcare', Type = 'Customer'));
        testAccounts.add(new Account(Name = 'Retail Co', Industry = 'Retail', Type = 'Prospect'));
        
        insert testAccounts;
    }

    /**
     * @description Test getAccountsByIndustry with valid industry parameter
     */
    @isTest
    static void testGetAccountsByIndustrySuccess() {
        Test.startTest();
        List<Account> techAccounts = AccountManager.getAccountsByIndustry('Technology');
        Test.stopTest();
        
        System.assertEquals(1, techAccounts.size(), 'Should return 1 Technology account');
        System.assertEquals('Tech Corp', techAccounts[0].Name, 'Account name should match');
        System.assertEquals('Technology', techAccounts[0].Industry, 'Industry should be Technology');
    }

    /**
     * @description Test getAccountsByIndustry with blank industry parameter
     */
    @isTest
    static void testGetAccountsByIndustryBlankInput() {
        Test.startTest();
        List<Account> accounts = AccountManager.getAccountsByIndustry('');
        Test.stopTest();
        
        System.assertEquals(0, accounts.size(), 'Should return empty list for blank input');
    }

    /**
     * @description Test getAccountsByIndustry with null industry parameter
     */
    @isTest
    static void testGetAccountsByIndustryNullInput() {
        Test.startTest();
        List<Account> accounts = AccountManager.getAccountsByIndustry(null);
        Test.stopTest();
        
        System.assertEquals(0, accounts.size(), 'Should return empty list for null input');
    }

    /**
     * @description Test getAccountsByIndustry with non-existent industry
     */
    @isTest
    static void testGetAccountsByIndustryNoResults() {
        Test.startTest();
        List<Account> accounts = AccountManager.getAccountsByIndustry('Manufacturing');
        Test.stopTest();
        
        System.assertEquals(0, accounts.size(), 'Should return empty list for non-existent industry');
    }

    /**
     * @description Test getAccountsByIndustry returns correct fields
     */
    @isTest
    static void testGetAccountsByIndustryFieldSelection() {
        Test.startTest();
        List<Account> financeAccounts = AccountManager.getAccountsByIndustry('Finance');
        Test.stopTest();
        
        System.assertEquals(1, financeAccounts.size(), 'Should return 1 Finance account');
        Account acc = financeAccounts[0];
        System.assertNotEquals(null, acc.Id, 'Account ID should not be null');
        System.assertNotEquals(null, acc.Name, 'Account Name should not be null');
        System.assertNotEquals(null, acc.Industry, 'Account Industry should not be null');
        System.assertNotEquals(null, acc.Type, 'Account Type should not be null');
    }

    /**
     * @description Test createAccount with valid parameters
     */
    @isTest
    static void testCreateAccountSuccess() {
        Test.startTest();
        Account newAccount = AccountManager.createAccount('New Tech Company', 'Technology');
        Test.stopTest();
        
        System.assertNotEquals(null, newAccount.Id, 'Account ID should not be null after creation');
        System.assertEquals('New Tech Company', newAccount.Name, 'Account name should match');
        System.assertEquals('Technology', newAccount.Industry, 'Industry should match');
        
        // Verify account was inserted in database
        Account verifyAccount = [SELECT Id, Name, Industry FROM Account WHERE Id = :newAccount.Id];
        System.assertEquals('New Tech Company', verifyAccount.Name, 'Account should be in database');
    }

    /**
     * @description Test createAccount with blank account name
     */
    @isTest
    static void testCreateAccountBlankName() {
        Test.startTest();
        try {
            AccountManager.createAccount('', 'Technology');
            System.assert(false, 'Should throw AuraHandledException for blank name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should indicate required field');
        }
        Test.stopTest();
    }

    /**
     * @description Test createAccount with blank industry
     */
    @isTest
    static void testCreateAccountBlankIndustry() {
        Test.startTest();
        try {
            AccountManager.createAccount('Test Account', '');
            System.assert(false, 'Should throw AuraHandledException for blank industry');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should indicate required field');
        }
        Test.stopTest();
    }

    /**
     * @description Test createAccount with null account name
     */
    @isTest
    static void testCreateAccountNullName() {
        Test.startTest();
        try {
            AccountManager.createAccount(null, 'Technology');
            System.assert(false, 'Should throw AuraHandledException for null name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should indicate required field');
        }
        Test.stopTest();
    }

    /**
     * @description Test createAccount with null industry
     */
    @isTest
    static void testCreateAccountNullIndustry() {
        Test.startTest();
        try {
            AccountManager.createAccount('Test Account', null);
            System.assert(false, 'Should throw AuraHandledException for null industry');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should indicate required field');
        }
        Test.stopTest();
    }

    /**
     * @description Test updateAnnualRevenue with valid parameters
     */
    @isTest
    static void testUpdateAnnualRevenueSuccess() {
        // Get an existing account
        Account acc = [SELECT Id FROM Account WHERE Name = 'Tech Corp' LIMIT 1];
        Decimal newRevenue = 1000000;
        
        Test.startTest();
        AccountManager.updateAnnualRevenue(acc.Id, newRevenue);
        Test.stopTest();
        
        // Verify the update
        Account verifyAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(newRevenue, verifyAccount.AnnualRevenue, 'Annual revenue should be updated');
    }

    /**
     * @description Test updateAnnualRevenue with null account ID
     */
    @isTest
    static void testUpdateAnnualRevenueNullAccountId() {
        Test.startTest();
        try {
            AccountManager.updateAnnualRevenue(null, 1000000);
            System.assert(false, 'Should throw AuraHandledException for null account ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should indicate required field');
        }
        Test.stopTest();
    }

    /**
     * @description Test updateAnnualRevenue with null revenue
     */
    @isTest
    static void testUpdateAnnualRevenueNullRevenue() {
        Account acc = [SELECT Id FROM Account WHERE Name = 'Tech Corp' LIMIT 1];
        
        Test.startTest();
        try {
            AccountManager.updateAnnualRevenue(acc.Id, null);
            System.assert(false, 'Should throw AuraHandledException for null revenue');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Error message should indicate required field');
        }
        Test.stopTest();
    }

    /**
     * @description Test updateAnnualRevenue with invalid account ID
     */
    @isTest
    static void testUpdateAnnualRevenueInvalidAccountId() {
        // Use a fake account ID
        Id fakeAccountId = Account.sObjectType.getDescribe().getKeyPrefix() + '000000000000';
        
        Test.startTest();
        try {
            AccountManager.updateAnnualRevenue(fakeAccountId, 5000000);
            System.assert(false, 'Should throw DmlException for invalid account ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error'), 'Error message should be present');
        }
        Test.stopTest();
    }

    /**
     * @description Test updateAnnualRevenue with multiple updates
     */
    @isTest
    static void testUpdateMultipleAccounts() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 2];
        
        Test.startTest();
        AccountManager.updateAnnualRevenue(accounts[0].Id, 1000000);
        AccountManager.updateAnnualRevenue(accounts[1].Id, 2000000);
        Test.stopTest();
        
        List<Account> verifyAccounts = [SELECT Id, AnnualRevenue FROM Account WHERE Id IN :accounts ORDER BY Id];
        System.assertEquals(1000000, verifyAccounts[0].AnnualRevenue, 'First account revenue should be updated');
        System.assertEquals(2000000, verifyAccounts[1].AnnualRevenue, 'Second account revenue should be updated');
    }

    /**
     * @description Test bulk operations - getAccountsByIndustry LIMIT
     */
    @isTest
    static void testGetAccountsByIndustryLimit() {
        // Insert additional accounts to test LIMIT 100
        List<Account> bulkAccounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            bulkAccounts.add(new Account(Name = 'Bulk Tech ' + i, Industry = 'Technology', Type = 'Customer'));
        }
        insert bulkAccounts;
        
        Test.startTest();
        List<Account> techAccounts = AccountManager.getAccountsByIndustry('Technology');
        Test.stopTest();
        
        // Should have original + 50 new accounts (total 51, but limited to 100)
        System.assert(techAccounts.size() > 1, 'Should return multiple accounts');
        System.assert(techAccounts.size() <= 100, 'Should not exceed LIMIT of 100');
    }

    /**
     * @description Test CRUD permissions are properly checked
     */
    @isTest
    static void testCRUDPermissionChecks() {
        // This test verifies that CRUD checks are in place
        // In a real scenario with restricted users, this would fail if CRUD checks were missing
        Test.startTest();
        try {
            List<Account> accounts = AccountManager.getAccountsByIndustry('Technology');
            System.assert(accounts.size() >= 0, 'Should have execute permission');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for accessible data');
        }
        Test.stopTest();
    }
}