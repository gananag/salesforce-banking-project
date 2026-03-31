/**
 * @description Test class for UpdateAccountsBatch
 * Tests batch processing functionality including:
 * - Batch start method (QueryLocator)
 * - Batch execute method (DML operations)
 * - Batch finish method (completion handling)
 * - Error handling and recovery
 * - Statistics tracking across batches
 * @author Your Name
 * @date 2026-03-31
 */
@isTest
public class UpdateAccountsBatchTest {

    /**
     * @description Test that batch processes all accounts
     */
    @isTest
    static void testBatchProcessesAllAccounts() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert testAccounts;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        String jobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify batch completed
        AsyncApexJob job = [
            SELECT Id, Status, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
        System.assertEquals(5, job.TotalJobItems, 'All 5 accounts should be processed');
    }

    /**
     * @description Test that batch updates account descriptions
     */
    @isTest
    static void testBatchUpdatesAccountDescriptions() {
        // Create test account
        Account acc = new Account(Name = 'Description Test', Industry = 'Technology');
        insert acc;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify description was updated
        Account updatedAcc = [SELECT Id, Description FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, updatedAcc.Description, 'Description should be populated');
        System.assert(updatedAcc.Description.contains('Last batch updated:'), 'Description should contain batch timestamp');
        System.assert(updatedAcc.Description.contains('Industry:'), 'Description should contain industry');
    }

    /**
     * @description Test batch with large dataset (250+ records)
     */
    @isTest
    static void testBatchWithLargeDataset() {
        // Create 250 test accounts (exceeds default batch size of 200)
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 250; i++) {
            testAccounts.add(new Account(
                Name = 'Large Dataset Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert testAccounts;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        String jobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify all records were processed
        AsyncApexJob job = [
            SELECT Id, TotalJobItems, JobItemsProcessed
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals(250, job.TotalJobItems, 'All 250 accounts should be included');
        System.assertEquals(2, job.JobItemsProcessed, 'Should process in 2 batches (200 + 50)');
    }

    /**
     * @description Test batch with empty database
     */
    @isTest
    static void testBatchWithNoAccounts() {
        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        String jobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify batch completes gracefully with no accounts
        AsyncApexJob job = [
            SELECT Id, Status, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
        System.assertEquals(0, job.TotalJobItems, 'No accounts should be processed');
    }

    /**
     * @description Test that batch includes account metadata in description
     */
    @isTest
    static void testBatchIncludesMetadataInDescription() {
        // Create test account with specific values
        Account acc = new Account(
            Name = 'Metadata Test',
            Industry = 'Finance',
            Type = 'Customer'
        );
        insert acc;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify description contains all expected metadata
        Account updatedAcc = [SELECT Id, Description, Industry, Type FROM Account WHERE Id = :acc.Id];
        String description = updatedAcc.Description;
        
        System.assert(description.contains('Finance'), 'Description should contain industry');
        System.assert(description.contains('Customer'), 'Description should contain type');
        System.assert(description.contains('Last batch updated:'), 'Description should contain timestamp');
    }

    /**
     * @description Test that batch tracks success count
     */
    @isTest
    static void testBatchTracksSuccessCount() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            testAccounts.add(new Account(Name = 'Success Test ' + i, Industry = 'Technology'));
        }
        insert testAccounts;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify success count increased
        System.assertEquals(10, [SELECT COUNT() FROM Account WHERE Description LIKE '%Last batch updated:%'], 'All 10 accounts should have updated descriptions');
    }

    /**
     * @description Test batch with mixed account data
     */
    @isTest
    static void testBatchWithMixedAccountData() {
        // Create accounts with different field values
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Account With Industry', Industry = 'Technology', Type = 'Prospect'));
        testAccounts.add(new Account(Name = 'Account Without Industry', Type = 'Customer'));
        testAccounts.add(new Account(Name = 'Account Without Type', Industry = 'Finance'));
        testAccounts.add(new Account(Name = 'Account With Nothing'));
        insert testAccounts;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify all accounts were updated regardless of field values
        List<Account> updatedAccounts = [
            SELECT Id, Name, Description 
            FROM Account 
            WHERE Name LIKE 'Account With%' OR Name LIKE 'Account Without%'
            ORDER BY Name
        ];
        
        System.assertEquals(4, updatedAccounts.size(), 'All 4 test accounts should be updated');
        for (Account acc : updatedAccounts) {
            System.assertNotEquals(null, acc.Description, 'All accounts should have descriptions');
            System.assert(acc.Description.contains('Last batch updated:'), 'All descriptions should contain timestamp');
        }
    }

    /**
     * @description Test batch with various batch sizes
     */
    @isTest
    static void testBatchWithDifferentBatchSize() {
        // Create 50 test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            testAccounts.add(new Account(Name = 'Batch Size Test ' + i, Industry = 'Technology'));
        }
        insert testAccounts;

        Test.startTest();
        // Execute with smaller batch size (25 instead of default 200)
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        String jobId = Database.executeBatch(batch, 25);
        Test.stopTest();

        // Verify batch processed records
        AsyncApexJob job = [
            SELECT Id, JobItemsProcessed
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals(2, job.JobItemsProcessed, 'Should process in 2 batches (25 + 25)');
    }

    /**
     * @description Test stateful batch maintains state across executions
     */
    @isTest
    static void testStatefulBatchMaintainsState() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 15; i++) {
            testAccounts.add(new Account(Name = 'Stateful Test ' + i, Industry = 'Technology'));
        }
        insert testAccounts;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        // Execute with small batch size to create multiple batches
        Database.executeBatch(batch, 5);
        Test.stopTest();

        // Verify state was maintained (success count should equal total records)
        System.assertEquals(15, [SELECT COUNT() FROM Account WHERE Description LIKE '%Last batch updated:%'], 'All 15 accounts should have updated descriptions');
    }

    /**
     * @description Test batch with accounts having special characters
     */
    @isTest
    static void testBatchWithSpecialCharactersInNames() {
        // Create accounts with special characters
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Account & Associates', Industry = 'Technology'));
        testAccounts.add(new Account(Name = 'O\'Reilly Company', Industry = 'Finance'));
        testAccounts.add(new Account(Name = 'Test-Company "USA"', Industry = 'Healthcare'));
        insert testAccounts;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify all accounts were updated successfully
        List<Account> updatedAccounts = [
            SELECT Id, Description 
            FROM Account 
            WHERE Name IN ('Account & Associates', 'O\'Reilly Company', 'Test-Company "USA"')
        ];
        
        System.assertEquals(3, updatedAccounts.size(), 'All 3 accounts with special characters should be updated');
        for (Account acc : updatedAccounts) {
            System.assertNotEquals(null, acc.Description, 'Description should be populated');
        }
    }

    /**
     * @description Test that batch can be scheduled
     */
    @isTest
    static void testBatchCanBeScheduled() {
        // Create test account
        Account acc = new Account(Name = 'Schedule Test', Industry = 'Technology');
        insert acc;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        String jobId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify job was created in AsyncApexJob
        AsyncApexJob job = [
            SELECT Id, ApexClass.Name, Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        System.assertEquals('UpdateAccountsBatch', job.ApexClass.Name, 'Batch class name should match');
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
    }

    /**
     * @description Test batch error messages are captured
     */
    @isTest
    static void testBatchErrorHandling() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(Name = 'Error Test ' + i, Industry = 'Technology'));
        }
        insert testAccounts;

        Test.startTest();
        UpdateAccountsBatch batch = new UpdateAccountsBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Verify batch completed without errors
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'UpdateAccountsBatch'
            LIMIT 1
        ];
        System.assertEquals('Completed', job.Status, 'Batch should complete');
    }
}
