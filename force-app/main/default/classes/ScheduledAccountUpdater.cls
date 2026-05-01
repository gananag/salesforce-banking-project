/**
 * @description Schedulable class to execute UpdateAccountsBatch on a scheduled basis
 * Implements the Schedulable interface for scheduled job execution
 * Can be scheduled daily, hourly, or at custom intervals through Setup > Scheduled Jobs
 * 
 * Example scheduling via Anonymous Apex:
 * ScheduledAccountUpdater scheduler = new ScheduledAccountUpdater();
 * String cronExpression = '0 0 2 * * ?'; // Daily at 2 AM
 * System.schedule('Scheduled Account Updater', cronExpression, scheduler);
 * 
 * @author Your Name
 * @date 2026-03-31
 */
public class ScheduledAccountUpdater implements Schedulable {

    /**
     * @description Executes the scheduled job
     * This method is called by Salesforce at the scheduled time
     * Creates and executes an instance of UpdateAccountsBatch
     * 
     * @param ctx SchedulableContext provided by Salesforce containing job information
     */
    public void execute(SchedulableContext ctx) {
        try {
            // Create instance of the batch class
            UpdateAccountsBatch batch = new UpdateAccountsBatch();
            
            // Execute batch with default batch size of 200
            String jobId = Database.executeBatch(batch, 200);
            
            // Log successful execution
            logScheduledJobExecution(ctx.getTriggerId(), jobId, true, null);
            
            System.debug(LoggingLevel.INFO, 'Scheduled Account Updater started batch job: ' + jobId);
        } catch (Exception e) {
            // Log failed execution
            logScheduledJobExecution(ctx.getTriggerId(), null, false, e.getMessage());
            
            System.debug(LoggingLevel.ERROR, 'Error executing scheduled batch: ' + e.getMessage());
            // In production, you might want to send an email notification here
            // sendErrorNotification(e);
        }
    }

    /**
     * @description Logs the scheduled job execution for audit purposes
     * Stores execution details in debug logs
     * 
     * @param jobId The ID of the scheduled job
     * @param batchJobId The ID of the batch job that was created
     * @param isSuccess Whether the execution was successful
     * @param errorMessage Error message if execution failed
     */
    private static void logScheduledJobExecution(String jobId, String batchJobId, Boolean isSuccess, String errorMessage) {
        String logMessage = 'Scheduled Job Execution Log\n' +
            'Job ID: ' + jobId + '\n' +
            'Batch Job ID: ' + (batchJobId != null ? batchJobId : 'N/A') + '\n' +
            'Execution Time: ' + System.now().format('yyyy-MM-dd HH:mm:ss') + '\n' +
            'Status: ' + (isSuccess ? 'SUCCESS' : 'FAILED') + '\n' +
            'Executed By: ' + UserInfo.getName();
        
        if (errorMessage != null) {
            logMessage += '\nError Message: ' + errorMessage;
        }
        
        System.debug(LoggingLevel.INFO, logMessage);
    }

    /**
     * @description Generates a CRON expression for daily execution
     * Useful for scheduling the job programmatically
     * 
     * @param hour The hour (0-23) in 24-hour format
     * @param minute The minute (0-59)
     * @return CRON expression string for daily execution at specified time
     * 
     * Example: getDailySchedule(2, 0) returns '0 0 2 * * ?' for 2 AM daily
     */
    public static String getDailySchedule(Integer hour, Integer minute) {
        // CRON format: second minute hour day_of_month month day_of_week
        return '0 ' + minute + ' ' + hour + ' * * ?';
    }

    /**
     * @description Generates a CRON expression for hourly execution
     * 
     * @param minute The minute (0-59) to execute on each hour
     * @return CRON expression string for hourly execution
     * 
     * Example: getHourlySchedule(0) returns '0 0 * * * ?' for top of each hour
     */
    public static String getHourlySchedule(Integer minute) {
        return '0 ' + minute + ' * * * ?';
    }

    /**
     * @description Generates a CRON expression for weekly execution
     * 
     * @param dayOfWeek Day of week (1=Sunday, 2=Monday, ..., 7=Saturday)
     * @param hour Hour in 24-hour format (0-23)
     * @param minute Minute (0-59)
     * @return CRON expression string for weekly execution
     * 
     * Example: getWeeklySchedule(2, 2, 0) returns '0 0 2 ? * 2' for Mondays at 2 AM
     */
    public static String getWeeklySchedule(Integer dayOfWeek, Integer hour, Integer minute) {
        return '0 ' + minute + ' ' + hour + ' ? * ' + dayOfWeek;
    }
}
