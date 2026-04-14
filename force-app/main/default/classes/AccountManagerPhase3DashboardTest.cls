/**
 * @description Test class for Phase 3.2 Dashboard statistics functionality
 * Tests chart data generation for industry and type statistics
 * @author Your Name
 * @date 2026-04-15
 */
@isTest
public class AccountManagerPhase3DashboardTest {

    /**
     * @description Test retrieval of account statistics by industry
     */
    @isTest
    static void testGetAccountsByIndustryStats() {
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Tech Company 1', Industry = 'Technology'));
        testAccounts.add(new Account(Name = 'Tech Company 2', Industry = 'Technology'));
        testAccounts.add(new Account(Name = 'Finance Corp', Industry = 'Finance'));
        testAccounts.add(new Account(Name = 'Healthcare Inc', Industry = 'Healthcare'));
        insert testAccounts;

        Test.startTest();
        Map<String, Integer> result = AccountManager.getAccountsByIndustryStats();
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Should have 3 industries');
        System.assertEquals(2, result.get('Technology'), 'Technology should have 2 accounts');
        System.assertEquals(1, result.get('Finance'), 'Finance should have 1 account');
        System.assertEquals(1, result.get('Healthcare'), 'Healthcare should have 1 account');
    }

    /**
     * @description Test retrieval of account statistics by type
     */
    @isTest
    static void testGetAccountsByTypeStats() {
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Prospect 1', Type = 'Prospect'));
        testAccounts.add(new Account(Name = 'Prospect 2', Type = 'Prospect'));
        testAccounts.add(new Account(Name = 'Customer 1', Type = 'Customer'));
        insert testAccounts;

        Test.startTest();
        Map<String, Integer> result = AccountManager.getAccountsByTypeStats();
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should have 2 account types');
        System.assertEquals(2, result.get('Prospect'), 'Prospect should have 2 accounts');
        System.assertEquals(1, result.get('Customer'), 'Customer should have 1 account');
    }

    /**
     * @description Test overall account statistics
     */
    @isTest
    static void testGetAccountStatistics() {
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Account 1', AnnualRevenue = 100000));
        testAccounts.add(new Account(Name = 'Account 2', AnnualRevenue = 250000));
        testAccounts.add(new Account(Name = 'Account 3')); // No revenue
        insert testAccounts;

        Test.startTest();
        Map<String, Object> result = AccountManager.getAccountStatistics();
        Test.stopTest();

        System.assertEquals(3, result.get('totalAccounts'), 'Total accounts should be 3');
        System.assertEquals(2, result.get('accountsWithRevenue'), 'Accounts with revenue should be 2');
        System.assertEquals(350000, result.get('totalRevenue'), 'Total revenue should be 350000');
    }

    /**
     * @description Test industry statistics with null industry values
     */
    @isTest
    static void testGetAccountsByIndustryStatsWithNullIndustry() {
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Tech Company', Industry = 'Technology'));
        testAccounts.add(new Account(Name = 'No Industry Account')); // null industry
        insert testAccounts;

        Test.startTest();
        Map<String, Integer> result = AccountManager.getAccountsByIndustryStats();
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should only count accounts with industry');
        System.assertEquals(1, result.get('Technology'), 'Technology should have 1 account');
    }

    /**
     * @description Test type statistics with null type values
     */
    @isTest
    static void testGetAccountsByTypeStatsWithNullType() {
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Customer Account', Type = 'Customer'));
        testAccounts.add(new Account(Name = 'No Type Account')); // null type
        insert testAccounts;

        Test.startTest();
        Map<String, Integer> result = AccountManager.getAccountsByTypeStats();
        Test.stopTest();

        System.assertEquals(1, result.size(), 'Should only count accounts with type');
        System.assertEquals(1, result.get('Customer'), 'Customer should have 1 account');
    }

    /**
     * @description Test account statistics with zero revenue accounts
     */
    @isTest
    static void testGetAccountStatisticsWithNoRevenue() {
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Account 1'));
        testAccounts.add(new Account(Name = 'Account 2'));
        insert testAccounts;

        Test.startTest();
        Map<String, Object> result = AccountManager.getAccountStatistics();
        Test.stopTest();

        System.assertEquals(2, result.get('totalAccounts'), 'Total accounts should be 2');
        System.assertEquals(0, result.get('accountsWithRevenue'), 'Accounts with revenue should be 0');
        System.assertEquals(0, result.get('totalRevenue'), 'Total revenue should be 0');
    }

    /**
     * @description Test industry statistics with empty database
     */
    @isTest
    static void testGetAccountsByIndustryStatsEmpty() {
        Test.startTest();
        Map<String, Integer> result = AccountManager.getAccountsByIndustryStats();
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty map when no accounts exist');
    }

    /**
     * @description Test type statistics with empty database
     */
    @isTest
    static void testGetAccountsByTypeStatsEmpty() {
        Test.startTest();
        Map<String, Integer> result = AccountManager.getAccountsByTypeStats();
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty map when no accounts exist');
    }
}