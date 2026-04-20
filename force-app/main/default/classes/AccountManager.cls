/**
 * @description Sample Apex class for Salesforce Platform Developer 2
 * @author Your Name
 * @date 2026-03-04
 */
public class AccountManager {
    /**
     * @description Retrieves a list of accounts by industry
     * @param industry The industry to filter by
     * @return List of Account records
     */
    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByIndustry(String industry) {
        if (String.isBlank(industry)) {
            return new List<Account>();
        }
        
        if (!Account.sObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Account records.');
        }
        
        return [SELECT Id, Name, Industry, Type FROM Account WHERE Industry = :industry LIMIT 100];
    }

    /**
     * @description Creates a new account with basic information
     * @param accountName The name of the account
     * @param industry The industry of the account
     * @return The created Account record
     */
    @AuraEnabled
    public static Account createAccount(String accountName, String industry) {
        if (String.isBlank(accountName) || String.isBlank(industry)) {
            throw new AuraHandledException('Account name and industry are required.');
        }
        
        if (!Account.sObjectType.getDescribe().isCreateable()) {
            throw new AuraHandledException('You do not have permission to create Account records.');
        }
        
        if (!Account.sObjectType.getDescribe().fields.getMap().get('Name').getDescribe().isCreateable()) {
            throw new AuraHandledException('You do not have permission to create Name field.');
        }
        if (!Account.sObjectType.getDescribe().fields.getMap().get('Industry').getDescribe().isCreateable()) {
            throw new AuraHandledException('You do not have permission to create Industry field.');
        }
        
        try {
            Account acc = new Account(
                Name = accountName,
                Industry = industry
            );
            insert acc;
            return acc;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating account: ' + e.getMessage());
        }
    }

    /**
     * @description Updates account annual revenue
     * @param accountId The ID of the account to update
     * @param annualRevenue The new annual revenue
     */
    @AuraEnabled
    public static void updateAnnualRevenue(Id accountId, Decimal annualRevenue) {
        if (accountId == null || annualRevenue == null) {
            throw new AuraHandledException('Account ID and annual revenue are required.');
        }
        
        if (!Account.sObjectType.getDescribe().isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update Account records.');
        }
        
        if (!Account.sObjectType.getDescribe().fields.getMap().get('AnnualRevenue').getDescribe().isUpdateable()) {
            throw new AuraHandledException('You do not have permission to update AnnualRevenue field.');
        }
        
        try {
            Account acc = new Account(Id = accountId, AnnualRevenue = annualRevenue);
            update acc;
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating account: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves related contacts for a specific account
     * Phase 3.1: Display related records functionality
     * @param accountId The ID of the account
     * @return List of Contact records related to the account
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getRelatedContacts(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account ID is required.');
        }
        
        if (!Contact.sObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Contact records.');
        }
        
        return [
            SELECT Id, FirstName, LastName, Email, Phone, Title
            FROM Contact
            WHERE AccountId = :accountId
            ORDER BY LastName, FirstName
            LIMIT 100
        ];
    }

    /**
     * @description Retrieves related opportunities for a specific account
     * Phase 3.1: Display related records functionality
     * @param accountId The ID of the account
     * @return List of Opportunity records related to the account
     */
    @AuraEnabled(cacheable=true)
    public static List<Opportunity> getRelatedOpportunities(Id accountId) {
        if (accountId == null) {
            throw new AuraHandledException('Account ID is required.');
        }
        
        if (!Opportunity.sObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Opportunity records.');
        }
        
        return [
            SELECT Id, Name, Amount, StageName, CloseDate, Probability
            FROM Opportunity
            WHERE AccountId = :accountId
            ORDER BY CloseDate DESC
            LIMIT 100
        ];
    }

    /**
     * @description Retrieves account statistics grouped by industry
     * Phase 3.2: Dashboard statistics for pie chart
     * @return Map containing industry as key and account count as value
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getAccountsByIndustryStats() {
        if (!Account.sObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Account records.');
        }
        
        Map<String, Integer> industryStats = new Map<String, Integer>();
        
        for (AggregateResult ar : [
            SELECT Industry, COUNT(Id) cnt
            FROM Account
            WHERE Industry != null
            GROUP BY Industry
        ]) {
            String industry = (String) ar.get('Industry');
            Integer count = (Integer) ar.get('cnt');
            industryStats.put(industry, count);
        }
        
        return industryStats;
    }

    /**
     * @description Retrieves account statistics grouped by type
     * Phase 3.2: Dashboard statistics for bar chart
     * @return Map containing account type as key and account count as value
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getAccountsByTypeStats() {
        if (!Account.sObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Account records.');
        }
        
        Map<String, Integer> typeStats = new Map<String, Integer>();
        
        for (AggregateResult ar : [
            SELECT Type, COUNT(Id) cnt
            FROM Account
            WHERE Type != null
            GROUP BY Type
        ]) {
            String type = (String) ar.get('Type');
            Integer count = (Integer) ar.get('cnt');
            typeStats.put(type, count);
        }
        
        return typeStats;
    }

    /**
     * @description Retrieves overall account statistics for dashboard
     * Phase 3.2: Dashboard statistics summary
     * @return Map containing total accounts, accounts with revenue, and total revenue
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getAccountStatistics() {
        if (!Account.sObjectType.getDescribe().isAccessible()) {
            throw new AuraHandledException('You do not have permission to access Account records.');
        }
        
        Map<String, Object> stats = new Map<String, Object>();
        
        Integer totalAccounts = [SELECT COUNT() FROM Account];
        stats.put('totalAccounts', totalAccounts);
        
        Integer accountsWithRevenue = [SELECT COUNT() FROM Account WHERE AnnualRevenue != null];
        stats.put('accountsWithRevenue', accountsWithRevenue);
        
        AggregateResult totalRevenueResult = [
            SELECT SUM(AnnualRevenue) totalRevenue
            FROM Account
            WHERE AnnualRevenue != null
        ];
        Decimal totalRevenue = (Decimal) totalRevenueResult.get('totalRevenue');
        stats.put('totalRevenue', totalRevenue != null ? totalRevenue : 0);
        
        return stats;
    }
}