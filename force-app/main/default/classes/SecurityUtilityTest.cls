/**
 * @description Test class for SecurityUtility Phase 4.1 - Sharing Rules & Record-Level Security
 * Tests CRUD permissions, FLS checks, record access, and sharing functionality
 * @author Salesforce PD2 Project
 * @date 2026-04-16
 */
@isTest
private class SecurityUtilityTest {
    
    @testSetup
    static void setup() {
        // Create test accounts for security testing
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Security Test Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert testAccounts;
    }
    
    @isTest
    static void testHasCrudPermissionCreate() {
        Boolean hasPermission = SecurityUtility.hasCrudPermission('Account', 'CREATE');
        System.assertEquals(true, hasPermission, 'Should have CREATE permission for Account');
    }
    
    @isTest
    static void testHasCrudPermissionRead() {
        Boolean hasPermission = SecurityUtility.hasCrudPermission('Account', 'READ');
        System.assertEquals(true, hasPermission, 'Should have READ permission for Account');
    }
    
    @isTest
    static void testHasCrudPermissionUpdate() {
        Boolean hasPermission = SecurityUtility.hasCrudPermission('Account', 'UPDATE');
        System.assertEquals(true, hasPermission, 'Should have UPDATE permission for Account');
    }
    
    @isTest
    static void testHasCrudPermissionDelete() {
        Boolean hasPermission = SecurityUtility.hasCrudPermission('Account', 'DELETE');
        System.assertEquals(true, hasPermission, 'Should have DELETE permission for Account');
    }
    
    @isTest
    static void testHasCrudPermissionInvalidObject() {
        Boolean hasPermission = SecurityUtility.hasCrudPermission('NonExistentObject', 'READ');
        System.assertEquals(false, hasPermission, 'Should return false for invalid object');
    }
    
    @isTest
    static void testHasFieldAccessRead() {
        Boolean hasAccess = SecurityUtility.hasFieldAccess('Account', 'Name', 'READ');
        System.assertEquals(true, hasAccess, 'Should have READ access to Name field');
    }
    
    @isTest
    static void testHasFieldAccessUpdate() {
        Boolean hasAccess = SecurityUtility.hasFieldAccess('Account', 'Name', 'UPDATE');
        System.assertEquals(true, hasAccess, 'Should have UPDATE access to Name field');
    }
    
    @isTest
    static void testHasFieldAccessInvalidField() {
        Boolean hasAccess = SecurityUtility.hasFieldAccess('Account', 'NonExistentField', 'READ');
        System.assertEquals(false, hasAccess, 'Should return false for invalid field');
    }
    
    @isTest
    static void testGetCurrentUserContext() {
        Map<String, String> userContext = SecurityUtility.getCurrentUserContext();
        
        System.assertNotEquals(null, userContext, 'User context should not be null');
        System.assert(userContext.containsKey('UserId'), 'Should contain UserId');
        System.assert(userContext.containsKey('UserName'), 'Should contain UserName');
        System.assertNotEquals(null, userContext.get('UserId'), 'UserId should not be null');
    }
    
    @isTest
    static void testHasRecordAccess() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        System.assert(!accounts.isEmpty(), 'Test data should exist');
        
        Boolean hasAccess = SecurityUtility.hasRecordAccess(accounts[0].Id, 'READ');
        System.assertEquals(true, hasAccess, 'Should have READ access to own record');
    }
    
    @isTest
    static void testHasRecordAccessInvalidId() {
        Boolean hasAccess = SecurityUtility.hasRecordAccess(null, 'READ');
        System.assertEquals(false, hasAccess, 'Should return false for null record ID');
    }
    
    @isTest
    static void testIsRecordOwnerOrHasAccess() {
        List<Account> accounts = [SELECT Id, OwnerId FROM Account LIMIT 1];
        System.assert(!accounts.isEmpty(), 'Test data should exist');
        
        Boolean isOwner = SecurityUtility.isRecordOwnerOrHasAccess(accounts[0].Id, 'Account');
        System.assertEquals(true, isOwner, 'Should verify user owns or has access to record');
    }
    
    @isTest
    static void testShareAccountWithUser() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        System.assert(!accounts.isEmpty(), 'Test data should exist');
        
        Id testUserId = UserInfo.getUserId();
        
        Boolean shareSuccess = SecurityUtility.shareAccountWithUser(accounts[0].Id, testUserId, 'Read');
        System.assertEquals(true, shareSuccess, 'Should successfully share account');
        
        List<AccountShare> shares = [SELECT Id FROM AccountShare WHERE AccountId = :accounts[0].Id AND UserOrGroupId = :testUserId];
        System.assert(!shares.isEmpty(), 'AccountShare record should be created');
    }
    
    @isTest
    static void testRemoveAccountShare() {
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        System.assert(!accounts.isEmpty(), 'Test data should exist');
        
        Id testUserId = UserInfo.getUserId();
        
        SecurityUtility.shareAccountWithUser(accounts[0].Id, testUserId, 'Edit');
        Boolean removeSuccess = SecurityUtility.removeAccountShare(accounts[0].Id, testUserId);
        System.assertEquals(true, removeSuccess, 'Should successfully remove share');
        
        List<AccountShare> shares = [SELECT Id FROM AccountShare WHERE AccountId = :accounts[0].Id AND UserOrGroupId = :testUserId];
        System.assertEquals(0, shares.size(), 'AccountShare record should be deleted');
    }
    
    @isTest
    static void testShareAccountWithUserInvalidParams() {
        Boolean shareSuccess = SecurityUtility.shareAccountWithUser(null, null, 'Read');
        System.assertEquals(false, shareSuccess, 'Should return false for null parameters');
    }
    
    @isTest
    static void testHasCrudPermissionNullInput() {
        Boolean hasPermission = SecurityUtility.hasCrudPermission(null, 'READ');
        System.assertEquals(false, hasPermission, 'Should return false for null object type');
    }
}
