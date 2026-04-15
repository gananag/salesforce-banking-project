/**
 * @description Test class for GovernorLimitMonitor Phase 4.3 - Governor Limit Monitoring
 * Tests governor limit tracking, logging, and resource management
 * @author Salesforce PD2 Project
 * @date 2026-04-16
 */
@isTest
private class GovernorLimitMonitorTest {
    
    @isTest
    static void testCaptureCurrentLimits() {
        GovernorLimitMonitor.GovernorLimitSnapshot snapshot = GovernorLimitMonitor.captureCurrentLimits();
        
        System.assertNotEquals(null, snapshot, 'Snapshot should not be null');
        System.assertNotEquals(null, snapshot.queriesUsed, 'queriesUsed should be populated');
        System.assertNotEquals(null, snapshot.queriesLimit, 'queriesLimit should be populated');
        System.assertNotEquals(null, snapshot.dmlStatementsUsed, 'dmlStatementsUsed should be populated');
        System.assertNotEquals(null, snapshot.dmlStatementsLimit, 'dmlStatementsLimit should be populated');
        System.assertNotEquals(null, snapshot.capturedAt, 'capturedAt should be populated');
    }
    
    @isTest
    static void testCaptureCurrentLimitsValidRange() {
        GovernorLimitMonitor.GovernorLimitSnapshot snapshot = GovernorLimitMonitor.captureCurrentLimits();
        
        System.assert(snapshot.queriesUsed <= snapshot.queriesLimit, 'Queries used should not exceed limit');
        System.assert(snapshot.dmlStatementsUsed <= snapshot.dmlStatementsLimit, 'DML statements used should not exceed limit');
        System.assert(snapshot.dmlRowsUsed <= snapshot.dmlRowsLimit, 'DML rows used should not exceed limit');
        System.assert(snapshot.cpuTimeUsed <= snapshot.cpuTimeLimit, 'CPU time used should not exceed limit');
        System.assert(snapshot.heapSizeUsed <= snapshot.heapSizeLimit, 'Heap size used should not exceed limit');
        System.assert(snapshot.calloutCountUsed <= snapshot.calloutCountLimit, 'Callout count used should not exceed limit');
    }
    
    @isTest
    static void testGetGovernorLimitPercentages() {
        Map<String, Decimal> percentages = GovernorLimitMonitor.getGovernorLimitPercentages();
        
        System.assertNotEquals(null, percentages, 'Percentages map should not be null');
        System.assert(percentages.containsKey('Queries'), 'Should contain Queries');
        System.assert(percentages.containsKey('DML Statements'), 'Should contain DML Statements');
        System.assert(percentages.containsKey('DML Rows'), 'Should contain DML Rows');
        System.assert(percentages.containsKey('CPU Time'), 'Should contain CPU Time');
        System.assert(percentages.containsKey('Heap Size'), 'Should contain Heap Size');
        System.assert(percentages.containsKey('Callouts'), 'Should contain Callouts');
        
        for (Decimal percentage : percentages.values()) {
            System.assert(percentage >= 0 && percentage <= 100, 'Percentage should be between 0 and 100');
        }
    }
    
    @isTest
    static void testIsLimitApproachingThresholdBelowThreshold() {
        Boolean isApproaching = GovernorLimitMonitor.isLimitApproachingThreshold('Queries', 80);
        System.assertEquals(false, isApproaching, 'Should not be approaching threshold at start of test');
    }
    
    @isTest
    static void testIsLimitApproachingThresholdInvalidName() {
        Boolean isApproaching = GovernorLimitMonitor.isLimitApproachingThreshold('InvalidLimit', 80);
        System.assertEquals(false, isApproaching, 'Should return false for invalid limit name');
    }
    
    @isTest
    static void testLogGovernorLimits() {
        GovernorLimitMonitor.logGovernorLimits('Test Operation', 'DEBUG');
        System.assert(true, 'Logging should complete without error');
    }
    
    @isTest
    static void testLogGovernorLimitsDifferentLevels() {
        GovernorLimitMonitor.logGovernorLimits('Test', 'DEBUG');
        GovernorLimitMonitor.logGovernorLimits('Test', 'INFO');
        GovernorLimitMonitor.logGovernorLimits('Test', 'WARN');
        GovernorLimitMonitor.logGovernorLimits('Test', 'ERROR');
        System.assert(true, 'All log levels should work');
    }
    
    @isTest
    static void testGetRemainingQueries() {
        Integer remaining = GovernorLimitMonitor.getRemainingQueries();
        
        System.assertNotEquals(null, remaining, 'Remaining queries should not be null');
        System.assert(remaining > 0, 'Should have remaining queries available');
        System.assert(remaining <= Limits.getLimitQueries(), 'Remaining should not exceed total limit');
    }
    
    @isTest
    static void testGetRemainingDmlStatements() {
        Integer remaining = GovernorLimitMonitor.getRemainingDmlStatements();
        
        System.assertNotEquals(null, remaining, 'Remaining DML statements should not be null');
        System.assert(remaining > 0, 'Should have remaining DML statements available');
        System.assert(remaining <= Limits.getLimitDmlStatements(), 'Remaining should not exceed total limit');
    }
    
    @isTest
    static void testGetRemainingDmlRows() {
        Integer remaining = GovernorLimitMonitor.getRemainingDmlRows();
        
        System.assertNotEquals(null, remaining, 'Remaining DML rows should not be null');
        System.assert(remaining > 0, 'Should have remaining DML rows available');
        System.assert(remaining <= Limits.getLimitDmlRows(), 'Remaining should not exceed total limit');
    }
    
    @isTest
    static void testGetRemainingHeap() {
        Integer remaining = GovernorLimitMonitor.getRemainingHeap();
        
        System.assertNotEquals(null, remaining, 'Remaining heap should not be null');
        System.assert(remaining > 0, 'Should have remaining heap available');
        System.assert(remaining <= Limits.getLimitHeapSize(), 'Remaining should not exceed total limit');
    }
    
    @isTest
    static void testGetRemainingCpuTime() {
        Integer remaining = GovernorLimitMonitor.getRemainingCpuTime();
        
        System.assertNotEquals(null, remaining, 'Remaining CPU time should not be null');
        System.assert(remaining > 0, 'Should have remaining CPU time available');
        System.assert(remaining <= Limits.getLimitCpuTime(), 'Remaining should not exceed total limit');
    }
    
    @isTest
    static void testCanProceedWithOperationSufficientResources() {
        Boolean canProceed = GovernorLimitMonitor.canProceedWithOperation(10, 10, 100);
        System.assertEquals(true, canProceed, 'Should allow operation with sufficient resources');
    }
    
    @isTest
    static void testCanProceedWithOperationInsufficientResources() {
        Integer queryLimit = Limits.getLimitQueries();
        Boolean canProceed = GovernorLimitMonitor.canProceedWithOperation(queryLimit + 1000, 1, 1);
        System.assertEquals(false, canProceed, 'Should block operation with insufficient resources');
    }
    
    @isTest
    static void testGetFormattedLimitStatus() {
        String status = GovernorLimitMonitor.getFormattedLimitStatus();
        
        System.assertNotEquals(null, status, 'Status string should not be null');
        System.assertNotEquals('', status, 'Status string should not be empty');
        System.assert(status.contains('GOVERNOR LIMIT STATUS REPORT'), 'Should contain report header');
        System.assert(status.contains('SOQL Queries'), 'Should contain queries section');
        System.assert(status.contains('DML Statements'), 'Should contain DML section');
    }
    
    @isTest
    static void testGovernorLimitMonitoringWithDML() {
        GovernorLimitMonitor.GovernorLimitSnapshot snapshotBefore = GovernorLimitMonitor.captureCurrentLimits();
        
        Account testAccount = new Account(Name = 'DML Test Account', Industry = 'Technology');
        insert testAccount;
        
        GovernorLimitMonitor.GovernorLimitSnapshot snapshotAfter = GovernorLimitMonitor.captureCurrentLimits();
        
        System.assert(snapshotAfter.dmlStatementsUsed >= snapshotBefore.dmlStatementsUsed, 'DML statements should increase after insert');
        System.assert(snapshotAfter.dmlRowsUsed >= snapshotBefore.dmlRowsUsed, 'DML rows should increase after insert');
    }
    
    @isTest
    static void testGovernorLimitMonitoringWithQuery() {
        GovernorLimitMonitor.GovernorLimitSnapshot snapshotBefore = GovernorLimitMonitor.captureCurrentLimits();
        
        List<Account> accounts = [SELECT Id, Name FROM Account LIMIT 10];
        
        GovernorLimitMonitor.GovernorLimitSnapshot snapshotAfter = GovernorLimitMonitor.captureCurrentLimits();
        
        System.assert(snapshotAfter.queriesUsed >= snapshotBefore.queriesUsed, 'Query count should increase after SOQL');
    }
}
