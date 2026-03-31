/**
 * @description Handler class for Account trigger logic following the handler pattern
 * Separates trigger logic from business logic for better maintainability and testability
 * @author Your Name
 * @date 2026-03-31
 */
public class AccountTriggerHandler {
    
    /**
     * @description Handles before insert trigger events
     * @param newAccounts List of new Account records being inserted
     */
    public static void handleBeforeInsert(List<Account> newAccounts) {
        validateAccountNames(newAccounts);
        populateDefaultType(newAccounts);
    }

    /**
     * @description Handles before update trigger events
     * @param newAccounts List of new Account records being updated
     * @param oldAccountsMap Map of old Account records keyed by ID
     */
    public static void handleBeforeUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        validateAccountNames(newAccounts);
        validateNameChange(newAccounts, oldAccountsMap);
        populateDefaultType(newAccounts);
    }

    /**
     * @description Handles after insert trigger events
     * @param newAccounts List of new Account records that were inserted
     */
    public static void handleAfterInsert(List<Account> newAccounts) {
        updateAccountMetadata(newAccounts, null, true);
    }

    /**
     * @description Handles after update trigger events
     * @param newAccounts List of new Account records that were updated
     * @param oldAccountsMap Map of old Account records keyed by ID
     */
    public static void handleAfterUpdate(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        updateAccountMetadata(newAccounts, oldAccountsMap, false);
    }

    /**
     * @description Validates that account names are unique and not blank
     * Prevents duplicate account names from being created
     * @param accounts List of Account records to validate
     */
    private static void validateAccountNames(List<Account> accounts) {
        Set<String> accountNames = new Set<String>();
        
        // Collect all account names being inserted/updated
        for (Account acc : accounts) {
            if (String.isNotBlank(acc.Name)) {
                accountNames.add(acc.Name.toLowerCase());
            }
        }

        // Query existing accounts to check for duplicates
        if (!accountNames.isEmpty()) {
            List<Account> existingAccounts = [
                SELECT Id, Name 
                FROM Account 
                WHERE LOWER(Name) IN :accountNames
                LIMIT 1000
            ];

            Set<String> existingNames = new Set<String>();
            for (Account existingAcc : existingAccounts) {
                existingNames.add(existingAcc.Name.toLowerCase());
            }

            // Add validation error if duplicate found
            for (Account acc : accounts) {
                if (String.isNotBlank(acc.Name) && existingNames.contains(acc.Name.toLowerCase())) {
                    acc.addError('An account with the name "' + acc.Name + '" already exists.');
                }
            }
        }
    }

    /**
     * @description Validates that account name is not being changed to a name that already exists
     * @param newAccounts List of new Account records
     * @param oldAccountsMap Map of old Account records
     */
    private static void validateNameChange(List<Account> newAccounts, Map<Id, Account> oldAccountsMap) {
        Set<String> changedNames = new Set<String>();

        // Identify which names have changed
        for (Account newAcc : newAccounts) {
            Account oldAcc = oldAccountsMap.get(newAcc.Id);
            if (newAcc.Name != oldAcc.Name) {
                changedNames.add(newAcc.Name.toLowerCase());
            }
        }

        // If names changed, check for duplicates
        if (!changedNames.isEmpty()) {
            List<Account> existingAccounts = [
                SELECT Id, Name 
                FROM Account 
                WHERE LOWER(Name) IN :changedNames 
                AND Id NOT IN :oldAccountsMap.keySet()
                LIMIT 1000
            ];

            Set<String> existingNames = new Set<String>();
            for (Account existingAcc : existingAccounts) {
                existingNames.add(existingAcc.Name.toLowerCase());
            }

            for (Account newAcc : newAccounts) {
                Account oldAcc = oldAccountsMap.get(newAcc.Id);
                if (newAcc.Name != oldAcc.Name && existingNames.contains(newAcc.Name.toLowerCase())) {
                    newAcc.addError('Cannot change name to "' + newAcc.Name + '" - this name already exists.');
                }
            }
        }
    }

    /**
     * @description Auto-populates the Type field with a default value if blank
     * @param accounts List of Account records to process
     */
    private static void populateDefaultType(List<Account> accounts) {
        for (Account acc : accounts) {
            if (String.isBlank(acc.Type)) {
                acc.Type = 'Prospect'; // Default type
            }
        }
    }

    /**
     * @description Updates account metadata including timestamps and description
     * Called after insert and update to track changes
     * @param newAccounts List of new Account records
     * @param oldAccountsMap Map of old Account records (null for insert)
     * @param isInsert Boolean indicating if this is an insert operation
     */
    private static void updateAccountMetadata(List<Account> newAccounts, Map<Id, Account> oldAccountsMap, Boolean isInsert) {
        List<Account> accountsToUpdate = new List<Account>();

        for (Account newAcc : newAccounts) {
            Boolean shouldUpdate = false;

            if (isInsert) {
                // For insert, always update metadata
                shouldUpdate = true;
            } else {
                // For update, only update if certain fields changed
                Account oldAcc = oldAccountsMap.get(newAcc.Id);
                if (newAcc.Name != oldAcc.Name || 
                    newAcc.Industry != oldAcc.Industry ||
                    newAcc.Type != oldAcc.Type) {
                    shouldUpdate = true;
                }
            }

            if (shouldUpdate) {
                accountsToUpdate.add(new Account(
                    Id = newAcc.Id,
                    Description = 'Last modified: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + ' by ' + UserInfo.getName()
                ));
            }
        }

        // Perform update in a separate DML operation to avoid recursion issues
        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating account metadata: ' + e.getMessage());
            }
        }
    }
}
