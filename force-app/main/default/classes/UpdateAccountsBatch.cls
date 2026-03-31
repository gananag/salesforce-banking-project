/**
 * @description Batch class to update all accounts with metadata
 * Demonstrates the Database.Batchable interface pattern
 * Updates account descriptions with timestamp on batch execution
 * Implements proper error handling and batch processing
 * @author Your Name
 * @date 2026-03-31
 */
public class UpdateAccountsBatch implements Database.Batchable<sObject>, Database.Stateful {
    
    // Track statistics across batches
    public Integer successCount = 0;
    public Integer errorCount = 0;
    public List<String> errorMessages = new List<String>();

    /**
     * @description Defines the scope of records to be processed in the batch
     * @param bc BatchableContext provided by Salesforce
     * @return QueryLocator that queries all Account records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query all accounts to be updated
        return Database.getQueryLocator([
            SELECT Id, Name, Industry, Type, Description
            FROM Account
            ORDER BY CreatedDate DESC
        ]);
    }

    /**
     * @description Processes each batch of records (default batch size: 200)
     * Updates account descriptions with current timestamp and user info
     * @param bc BatchableContext provided by Salesforce
     * @param scope List of Account records to process in this batch
     */
    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Account> accountsToUpdate = new List<Account>();

        try {
            for (Account acc : scope) {
                Account updatedAcc = new Account(
                    Id = acc.Id,
                    Description = generateMetadataDescription(acc)
                );
                accountsToUpdate.add(updatedAcc);
            }

            // Perform DML with error handling
            if (!accountsToUpdate.isEmpty()) {
                Database.SaveResult[] results = Database.update(accountsToUpdate, false);
                
                // Process results to track success/errors
                for (Integer i = 0; i < results.size(); i++) {
                    if (results[i].isSuccess()) {
                        successCount++;
                    } else {
                        errorCount++;
                        for (Database.Error error : results[i].getErrors()) {
                            errorMessages.add(
                                'Account ID: ' + accountsToUpdate[i].Id + 
                                ' - Error: ' + error.getMessage()
                            );
                        }
                    }
                }
            }
        } catch (Exception e) {
            errorCount += scope.size();
            errorMessages.add('Batch execution error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Batch processing failed: ' + e.getMessage());
        }
    }

    /**
     * @description Called after all batches have been processed
     * Used to send completion notifications or schedule follow-up jobs
     * @param bc BatchableContext provided by Salesforce
     */
    public void finish(Database.BatchableContext bc) {
        // Log batch completion statistics
        String jobId = bc.getJobId();
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];

        String completionMessage = 'Batch Job Completed\n' +
            'Job ID: ' + jobId + '\n' +
            'Status: ' + job.Status + '\n' +
            'Total Records Processed: ' + job.TotalJobItems + '\n' +
            'Successful Updates: ' + successCount + '\n' +
            'Failed Updates: ' + errorCount + '\n' +
            'Job Items Processed: ' + job.JobItemsProcessed;

        if (!errorMessages.isEmpty()) {
            completionMessage += '\n\nError Details:\n';
            for (String error : errorMessages) {
                completionMessage += error + '\n';
            }
        }

        System.debug(LoggingLevel.INFO, completionMessage);

        // In production, you might send an email here:
        // sendCompletionEmail(completionMessage);
    }

    /**
     * @description Generates metadata description string for account
     * Includes timestamp and user information
     * @param acc Account record to generate description for
     * @return Formatted metadata description string
     */
    private static String generateMetadataDescription(Account acc) {
        String timestamp = System.now().format('yyyy-MM-dd HH:mm:ss');
        String userName = UserInfo.getName();
        
        return 'Last batch updated: ' + timestamp + ' by ' + userName + '\n' +
               'Industry: ' + (acc.Industry != null ? acc.Industry : 'N/A') + '\n' +
               'Type: ' + (acc.Type != null ? acc.Type : 'N/A');
    }
}
