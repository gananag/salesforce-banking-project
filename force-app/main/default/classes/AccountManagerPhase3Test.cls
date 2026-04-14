/**
 * @description Test class for Phase 3 related records functionality
 * Tests retrieving related contacts and opportunities for accounts
 * @author Your Name
 * @date 2026-04-15
 */
@isTest
public class AccountManagerPhase3Test {

    /**
     * @description Test retrieval of related contacts for an account
     */
    @isTest
    static void testGetRelatedContacts() {
        Account acc = new Account(Name = 'Test Account', Industry = 'Technology');
        insert acc;

        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                AccountId = acc.Id,
                Email = 'contact' + i + '@example.com',
                Phone = '555-000' + i
            ));
        }
        insert contacts;

        Test.startTest();
        List<Contact> result = AccountManager.getRelatedContacts(acc.Id);
        Test.stopTest();

        System.assertEquals(3, result.size(), 'Should retrieve 3 contacts');
        for (Contact c : result) {
            System.assertEquals(acc.Id, c.AccountId, 'Contact should belong to test account');
        }
    }

    /**
     * @description Test retrieval of related opportunities for an account
     */
    @isTest
    static void testGetRelatedOpportunities() {
        Account acc = new Account(Name = 'Test Account', Industry = 'Technology');
        insert acc;

        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 2; i++) {
            opportunities.add(new Opportunity(
                Name = 'Test Opp ' + i,
                AccountId = acc.Id,
                Amount = 10000 + (i * 1000),
                StageName = 'Prospecting',
                CloseDate = Date.today().addDays(30)
            ));
        }
        insert opportunities;

        Test.startTest();
        List<Opportunity> result = AccountManager.getRelatedOpportunities(acc.Id);
        Test.stopTest();

        System.assertEquals(2, result.size(), 'Should retrieve 2 opportunities');
        for (Opportunity opp : result) {
            System.assertEquals(acc.Id, opp.AccountId, 'Opportunity should belong to test account');
        }
    }

    /**
     * @description Test getRelatedContacts with null account ID
     */
    @isTest
    static void testGetRelatedContactsWithNullId() {
        Test.startTest();
        try {
            AccountManager.getRelatedContacts(null);
            System.fail('Should throw exception for null account ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account ID is required'), 'Should return proper error message');
        }
        Test.stopTest();
    }

    /**
     * @description Test getRelatedOpportunities with null account ID
     */
    @isTest
    static void testGetRelatedOpportunitiesWithNullId() {
        Test.startTest();
        try {
            AccountManager.getRelatedOpportunities(null);
            System.fail('Should throw exception for null account ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Account ID is required'), 'Should return proper error message');
        }
        Test.stopTest();
    }

    /**
     * @description Test getRelatedContacts with account that has no contacts
     */
    @isTest
    static void testGetRelatedContactsNoResults() {
        Account acc = new Account(Name = 'Empty Account', Industry = 'Technology');
        insert acc;

        Test.startTest();
        List<Contact> result = AccountManager.getRelatedContacts(acc.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for account with no contacts');
    }

    /**
     * @description Test getRelatedOpportunities with account that has no opportunities
     */
    @isTest
    static void testGetRelatedOpportunitiesNoResults() {
        Account acc = new Account(Name = 'Empty Account', Industry = 'Technology');
        insert acc;

        Test.startTest();
        List<Opportunity> result = AccountManager.getRelatedOpportunities(acc.Id);
        Test.stopTest();

        System.assertEquals(0, result.size(), 'Should return empty list for account with no opportunities');
    }
}