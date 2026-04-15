/**
 * @description Security Utility class for Phase 4.1 - Sharing Rules & Record-Level Security
 * Implements record-level sharing, ownership verification, and field-level security checks
 * @author Salesforce PD2 Project
 * @date 2026-04-16
 */
public class SecurityUtility {
    
    /**
     * @description Checks if the current user has access to a specific record
     * Phase 4.1: Record-level security check
     * @param recordId The ID of the record to check access for
     * @param accessLevel The required access level (READ, UPDATE, DELETE)
     * @return Boolean indicating if user has access
     */
    public static Boolean hasRecordAccess(Id recordId, String accessLevel) {
        if (recordId == null || String.isBlank(accessLevel)) {
            return false;
        }
        
        try {
            // Use UserRecordAccess to check record-level sharing
            List<UserRecordAccess> recordAccess = [
                SELECT RecordId, HasReadAccess, HasEditAccess, HasDeleteAccess
                FROM UserRecordAccess
                WHERE RecordId = :recordId AND UserId = :UserInfo.getUserId()
            ];
            
            if (recordAccess.isEmpty()) {
                return false;
            }
            
            UserRecordAccess access = recordAccess[0];
            
            switch on accessLevel.toUpperCase() {
                when 'READ' {
                    return access.HasReadAccess;
                }
                when 'UPDATE' {
                    return access.HasEditAccess;
                }
                when 'DELETE' {
                    return access.HasDeleteAccess;
                }
                when else {
                    return false;
                }
            }
        } catch (Exception e) {
            System.debug('Error checking record access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Verifies user owns or has access to a record
     * Phase 4.1: Ownership verification
     * @param recordId The ID of the record
     * @param sObjectType The type of SObject (e.g., 'Account')
     * @return Boolean indicating if user owns or can access the record
     */
    public static Boolean isRecordOwnerOrHasAccess(Id recordId, String sObjectType) {
        if (recordId == null || String.isBlank(sObjectType)) {
            return false;
        }
        
        Id currentUserId = UserInfo.getUserId();
        
        try {
            // Query the OwnerId field using dynamic SOQL
            String query = 'SELECT OwnerId FROM ' + sObjectType + ' WHERE Id = :recordId LIMIT 1';
            List<SObject> records = Database.query(query);
            
            if (records.isEmpty()) {
                return false;
            }
            
            Id recordOwnerId = (Id) records[0].get('OwnerId');
            return recordOwnerId == currentUserId || hasRecordAccess(recordId, 'UPDATE');
        } catch (Exception e) {
            System.debug('Error verifying record ownership: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Checks if user can access a specific field on an object
     * Phase 4.1: Field-level security (FLS) check
     * @param sObjectType The type of SObject
     * @param fieldName The name of the field to check
     * @param accessType The type of access (READ, UPDATE)
     * @return Boolean indicating if user has FLS access
     */
    public static Boolean hasFieldAccess(String sObjectType, String fieldName, String accessType) {
        if (String.isBlank(sObjectType) || String.isBlank(fieldName) || String.isBlank(accessType)) {
            return false;
        }
        
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(sObjectType);
            if (objType == null) {
                return false;
            }
            
            Map<String, SObjectField> fieldMap = objType.getDescribe().fields.getMap();
            SObjectField field = fieldMap.get(fieldName.toLowerCase());
            
            if (field == null) {
                return false;
            }
            
            DescribeFieldResult fieldDescribe = field.getDescribe();
            
            switch on accessType.toUpperCase() {
                when 'READ' {
                    return fieldDescribe.isAccessible();
                }
                when 'UPDATE' {
                    return fieldDescribe.isUpdateable();
                }
                when 'CREATE' {
                    return fieldDescribe.isCreateable();
                }
                when else {
                    return false;
                }
            }
        } catch (Exception e) {
            System.debug('Error checking field access: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Checks CRUD permissions for an object
     * Phase 4.1: Object-level CRUD check
     * @param sObjectType The type of SObject
     * @param crudType The type of permission (CREATE, READ, UPDATE, DELETE)
     * @return Boolean indicating if user has CRUD permission
     */
    public static Boolean hasCrudPermission(String sObjectType, String crudType) {
        if (String.isBlank(sObjectType) || String.isBlank(crudType)) {
            return false;
        }
        
        try {
            SObjectType objType = Schema.getGlobalDescribe().get(sObjectType);
            if (objType == null) {
                return false;
            }
            
            DescribeSObjectResult objDescribe = objType.getDescribe();
            
            switch on crudType.toUpperCase() {
                when 'CREATE' {
                    return objDescribe.isCreateable();
                }
                when 'READ' {
                    return objDescribe.isAccessible();
                }
                when 'UPDATE' {
                    return objDescribe.isUpdateable();
                }
                when 'DELETE' {
                    return objDescribe.isDeletable();
                }
                when else {
                    return false;
                }
            }
        } catch (Exception e) {
            System.debug('Error checking CRUD permission: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Gets the current user's ID and profile name
     * Phase 4.1: User context information
     * @return Map containing UserId, Username, and ProfileName
     */
    public static Map<String, String> getCurrentUserContext() {
        Map<String, String> userContext = new Map<String, String>();
        
        Id userId = UserInfo.getUserId();
        String userName = UserInfo.getUserName();
        
        userContext.put('UserId', userId);
        userContext.put('UserName', userName);
        
        try {
            List<User> users = [SELECT Id, Profile.Name FROM User WHERE Id = :userId LIMIT 1];
            if (!users.isEmpty()) {
                userContext.put('ProfileName', users[0].Profile.Name);
            }
        } catch (Exception e) {
            System.debug('Error getting user context: ' + e.getMessage());
        }
        
        return userContext;
    }
    
    /**
     * @description Shares an Account record with a specific user
     * Phase 4.1: Manual sharing implementation
     * @param accountId The ID of the account to share
     * @param userId The ID of the user to share with
     * @param accessLevel The access level (Read, Edit, All)
     * @return Boolean indicating success
     */
    public static Boolean shareAccountWithUser(Id accountId, Id userId, String accessLevel) {
        if (accountId == null || userId == null || String.isBlank(accessLevel)) {
            return false;
        }
        
        try {
            AccountShare share = new AccountShare();
            share.AccountId = accountId;
            share.UserOrGroupId = userId;
            
            switch on accessLevel.toUpperCase() {
                when 'READ' {
                    share.AccountAccessLevel = 'Read';
                }
                when 'EDIT' {
                    share.AccountAccessLevel = 'Edit';
                }
                when 'ALL' {
                    share.AccountAccessLevel = 'All';
                }
                when else {
                    return false;
                }
            }
            
            insert share;
            return true;
        } catch (DmlException e) {
            System.debug('Error sharing account: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Removes sharing of an Account record with a specific user
     * Phase 4.1: Manual sharing removal
     * @param accountId The ID of the account
     * @param userId The ID of the user to remove sharing from
     * @return Boolean indicating success
     */
    public static Boolean removeAccountShare(Id accountId, Id userId) {
        if (accountId == null || userId == null) {
            return false;
        }
        
        try {
            List<AccountShare> shares = [
                SELECT Id FROM AccountShare
                WHERE AccountId = :accountId AND UserOrGroupId = :userId
            ];
            
            if (!shares.isEmpty()) {
                delete shares;
                return true;
            }
            return false;
        } catch (DmlException e) {
            System.debug('Error removing account share: ' + e.getMessage());
            return false;
        }
    }
}
