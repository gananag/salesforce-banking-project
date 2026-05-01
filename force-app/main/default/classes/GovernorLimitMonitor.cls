/**
 * @description Governor Limit Monitoring Utility class for Phase 4.3 - Governor Limit Monitoring
 * Tracks and logs governor limit usage to prevent hitting platform limits
 * @author Salesforce PD2 Project
 * @date 2026-04-16
 */
public class GovernorLimitMonitor {
    
    // Inner class to hold governor limit data
    public class GovernorLimitSnapshot {
        public Integer queriesUsed { get; set; }
        public Integer queriesLimit { get; set; }
        public Integer dmlStatementsUsed { get; set; }
        public Integer dmlStatementsLimit { get; set; }
        public Integer dmlRowsUsed { get; set; }
        public Integer dmlRowsLimit { get; set; }
        public Integer cpuTimeUsed { get; set; }
        public Integer cpuTimeLimit { get; set; }
        public Integer heapSizeUsed { get; set; }
        public Integer heapSizeLimit { get; set; }
        public Integer calloutCountUsed { get; set; }
        public Integer calloutCountLimit { get; set; }
        public Integer soqlQueriesUsed { get; set; }
        public Integer soqlQueriesLimit { get; set; }
        public Datetime capturedAt { get; set; }
    }
    
    /**
     * @description Captures current governor limit usage
     * Phase 4.3: Governor limit monitoring - Capture current state
     * @return GovernorLimitSnapshot containing all current limits
     */
    public static GovernorLimitSnapshot captureCurrentLimits() {
        GovernorLimitSnapshot snapshot = new GovernorLimitSnapshot();
        
        snapshot.queriesUsed = Limits.getQueries();
        snapshot.queriesLimit = Limits.getLimitQueries();
        
        snapshot.dmlStatementsUsed = Limits.getDmlStatements();
        snapshot.dmlStatementsLimit = Limits.getLimitDmlStatements();
        
        snapshot.dmlRowsUsed = Limits.getDmlRows();
        snapshot.dmlRowsLimit = Limits.getLimitDmlRows();
        
        snapshot.cpuTimeUsed = Limits.getCpuTime();
        snapshot.cpuTimeLimit = Limits.getLimitCpuTime();
        
        snapshot.heapSizeUsed = Limits.getHeapSize();
        snapshot.heapSizeLimit = Limits.getLimitHeapSize();
        
        snapshot.calloutCountUsed = Limits.getCallouts();
        snapshot.calloutCountLimit = Limits.getLimitCallouts();
        
        snapshot.soqlQueriesUsed = Limits.getQueries();
        snapshot.soqlQueriesLimit = Limits.getLimitQueries();
        
        snapshot.capturedAt = System.now();
        
        return snapshot;
    }
    
    /**
     * @description Gets percentage of governor limit used
     * Phase 4.3: Governor limit monitoring - Calculate usage percentage
     * @return Map of limit name to percentage used (0-100)
     */
    public static Map<String, Decimal> getGovernorLimitPercentages() {
        Map<String, Decimal> percentages = new Map<String, Decimal>();
        
        GovernorLimitSnapshot snapshot = captureCurrentLimits();
        
        percentages.put('Queries', calculatePercentage(snapshot.queriesUsed, snapshot.queriesLimit));
        percentages.put('DML Statements', calculatePercentage(snapshot.dmlStatementsUsed, snapshot.dmlStatementsLimit));
        percentages.put('DML Rows', calculatePercentage(snapshot.dmlRowsUsed, snapshot.dmlRowsLimit));
        percentages.put('CPU Time', calculatePercentage(snapshot.cpuTimeUsed, snapshot.cpuTimeLimit));
        percentages.put('Heap Size', calculatePercentage(snapshot.heapSizeUsed, snapshot.heapSizeLimit));
        percentages.put('Callouts', calculatePercentage(snapshot.calloutCountUsed, snapshot.calloutCountLimit));
        
        return percentages;
    }
    
    /**
     * @description Calculates percentage of limit used
     * Phase 4.3: Governor limit monitoring - Utility calculation
     * @param used Amount used
     * @param limitAmount Total limit
     * @return Decimal percentage (0-100)
     */
    private static Decimal calculatePercentage(Integer used, Integer limitAmount) {
        if (limitAmount == 0) {
            return 0;
        }
        return (Decimal.valueOf(used) / Decimal.valueOf(limitAmount)) * 100;
    }
    
    /**
     * @description Checks if a specific governor limit is approaching threshold
     * Phase 4.3: Governor limit monitoring - Threshold checking
     * @param limitName Name of the limit to check (e.g., 'Queries', 'DML Statements')
     * @param thresholdPercentage Percentage threshold (e.g., 80 for 80%)
     * @return Boolean indicating if limit is approaching threshold
     */
    public static Boolean isLimitApproachingThreshold(String limitName, Decimal thresholdPercentage) {
        Map<String, Decimal> percentages = getGovernorLimitPercentages();
        
        if (!percentages.containsKey(limitName)) {
            return false;
        }
        
        Decimal currentPercentage = percentages.get(limitName);
        return currentPercentage >= thresholdPercentage;
    }
    
    /**
     * @description Logs governor limit usage to System.debug and optionally to Apex logs
     * Phase 4.3: Governor limit monitoring - Detailed logging
     * @param operationName Name of the operation being monitored
     * @param logLevel Log level (DEBUG, INFO, WARN, ERROR)
     */
    public static void logGovernorLimits(String operationName, String logLevel) {
        GovernorLimitSnapshot snapshot = captureCurrentLimits();
        
        String logMessage = '=== Governor Limit Monitor: ' + operationName + ' ===\n';
        logMessage += 'Captured at: ' + snapshot.capturedAt + '\n';
        logMessage += 'SOQL Queries: ' + snapshot.queriesUsed + '/' + snapshot.queriesLimit + '\n';
        logMessage += 'DML Statements: ' + snapshot.dmlStatementsUsed + '/' + snapshot.dmlStatementsLimit + '\n';
        logMessage += 'DML Rows: ' + snapshot.dmlRowsUsed + '/' + snapshot.dmlRowsLimit + '\n';
        logMessage += 'CPU Time (ms): ' + snapshot.cpuTimeUsed + '/' + snapshot.cpuTimeLimit + '\n';
        logMessage += 'Heap Size (bytes): ' + snapshot.heapSizeUsed + '/' + snapshot.heapSizeLimit + '\n';
        logMessage += 'Callouts: ' + snapshot.calloutCountUsed + '/' + snapshot.calloutCountLimit;
        
        switch on logLevel.toUpperCase() {
            when 'DEBUG' {
                System.debug(LoggingLevel.DEBUG, logMessage);
            }
            when 'INFO' {
                System.debug(LoggingLevel.INFO, logMessage);
            }
            when 'WARN' {
                System.debug(LoggingLevel.WARN, logMessage);
            }
            when 'ERROR' {
                System.debug(LoggingLevel.ERROR, logMessage);
            }
            when else {
                System.debug(logMessage);
            }
        }
    }
    
    /**
     * @description Gets remaining queries available
     * Phase 4.3: Governor limit monitoring - Remaining resources
     * @return Integer number of queries remaining
     */
    public static Integer getRemainingQueries() {
        return Limits.getLimitQueries() - Limits.getQueries();
    }
    
    /**
     * @description Gets remaining DML statements available
     * Phase 4.3: Governor limit monitoring - Remaining resources
     * @return Integer number of DML statements remaining
     */
    public static Integer getRemainingDmlStatements() {
        return Limits.getLimitDmlStatements() - Limits.getDmlStatements();
    }
    
    /**
     * @description Gets remaining DML rows available
     * Phase 4.3: Governor limit monitoring - Remaining resources
     * @return Integer number of DML rows remaining
     */
    public static Integer getRemainingDmlRows() {
        return Limits.getLimitDmlRows() - Limits.getDmlRows();
    }
    
    /**
     * @description Gets remaining heap size available
     * Phase 4.3: Governor limit monitoring - Remaining resources
     * @return Integer bytes of heap remaining
     */
    public static Integer getRemainingHeap() {
        return Limits.getLimitHeapSize() - Limits.getHeapSize();
    }
    
    /**
     * @description Gets remaining CPU time available
     * Phase 4.3: Governor limit monitoring - Remaining resources
     * @return Integer milliseconds of CPU time remaining
     */
    public static Integer getRemainingCpuTime() {
        return Limits.getLimitCpuTime() - Limits.getCpuTime();
    }
    
    /**
     * @description Checks if operation should proceed based on remaining limits
     * Phase 4.3: Governor limit monitoring - Safety check
     * @param estimatedQueries Estimated number of queries needed
     * @param estimatedDmlStatements Estimated number of DML statements needed
     * @param estimatedDmlRows Estimated number of DML rows needed
     * @return Boolean indicating if operation can safely proceed
     */
    public static Boolean canProceedWithOperation(Integer estimatedQueries, Integer estimatedDmlStatements, Integer estimatedDmlRows) {
        Integer remainingQueries = getRemainingQueries();
        Integer remainingDml = getRemainingDmlStatements();
        Integer remainingRows = getRemainingDmlRows();
        
        // Add safety buffer (20% cushion)
        return (remainingQueries > estimatedQueries * 1.2) &&
               (remainingDml > estimatedDmlStatements * 1.2) &&
               (remainingRows > estimatedDmlRows * 1.2);
    }
    
    /**
     * @description Gets a formatted string of current governor limit status
     * Phase 4.3: Governor limit monitoring - Status report
     * @return String containing formatted status
     */
    public static String getFormattedLimitStatus() {
        GovernorLimitSnapshot snapshot = captureCurrentLimits();
        Map<String, Decimal> percentages = getGovernorLimitPercentages();
        
        String status = 'GOVERNOR LIMIT STATUS REPORT\n';
        status += '================================\n\n';
        
        status += 'SOQL Queries:\n';
        status += '  Used: ' + snapshot.queriesUsed + '/' + snapshot.queriesLimit;
        status += ' (' + percentages.get('Queries').setScale(2) + '%)\n\n';
        
        status += 'DML Statements:\n';
        status += '  Used: ' + snapshot.dmlStatementsUsed + '/' + snapshot.dmlStatementsLimit;
        status += ' (' + percentages.get('DML Statements').setScale(2) + '%)\n\n';
        
        status += 'DML Rows:\n';
        status += '  Used: ' + snapshot.dmlRowsUsed + '/' + snapshot.dmlRowsLimit;
        status += ' (' + percentages.get('DML Rows').setScale(2) + '%)\n\n';
        
        status += 'CPU Time (ms):\n';
        status += '  Used: ' + snapshot.cpuTimeUsed + '/' + snapshot.cpuTimeLimit;
        status += ' (' + percentages.get('CPU Time').setScale(2) + '%)\n\n';
        
        status += 'Heap Size (bytes):\n';
        status += '  Used: ' + snapshot.heapSizeUsed + '/' + snapshot.heapSizeLimit;
        status += ' (' + percentages.get('Heap Size').setScale(2) + '%)\n\n';
        
        status += 'Callouts:\n';
        status += '  Used: ' + snapshot.calloutCountUsed + '/' + snapshot.calloutCountLimit;
        status += ' (' + percentages.get('Callouts').setScale(2) + '%)\n';
        
        return status;
    }
}
