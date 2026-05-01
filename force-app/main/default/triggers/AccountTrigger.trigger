/**
 * @description Trigger for Account object following the handler pattern
 * This trigger delegates all logic to the AccountTriggerHandler class
 * Benefits:
 * - Separates trigger logic from business logic
 * - Makes testing easier by allowing direct handler class testing
 * - Allows only one trigger per object (best practice)
 * - Improves code maintainability and reusability
 * @author Your Name
 * @date 2026-03-31
 */
trigger AccountTrigger on Account (before insert, before update, after insert, after update) {
    
    if (Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    else if (Trigger.isBefore && Trigger.isUpdate) {
        AccountTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    else if (Trigger.isAfter && Trigger.isInsert) {
        AccountTriggerHandler.handleAfterInsert(Trigger.new);
    }
    else if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}
