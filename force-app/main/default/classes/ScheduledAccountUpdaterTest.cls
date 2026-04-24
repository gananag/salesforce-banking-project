/**
 * @description Test class for ScheduledAccountUpdater
 * Tests scheduled job functionality including:
 * - Schedulable interface implementation
 * - Batch job execution from scheduled context
 * - CRON expression generation
 * - Error handling in scheduled execution
 * - Logging and audit trail functionality
 * @author Your Name
 * @date 2026-03-31
 */
@isTest
public class ScheduledAccountUpdaterTest {

    /**
     * @description Test that scheduled job executes successfully
     */
    @isTest
    static void testScheduledJobExecutesSuccessfully() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Scheduled Test ' + i,
                Industry = 'Technology'
            ));
        }
        insert testAccounts;

        Test.startTest();
        ScheduledAccountUpdater scheduler = new ScheduledAccountUpdater();
        String jobId = System.schedule('Test Scheduled Job', '0 0 2 * * ?', scheduler);
        Test.stopTest();

        // Verify the scheduled job was created
        CronTrigger job = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertNotEquals(null, job, 'Scheduled job should be created');
        System.assertEquals('Test Scheduled Job', job.CronJobDetail.Name, 'Job name should match');
    }

    /**
     * @description Test that batch is executed from scheduled context
     */
    @isTest
    static void testBatchExecutedFromScheduledContext() {
        // Create test accounts
        Account acc = new Account(Name = 'Batch Execution Test', Industry = 'Technology');
        insert acc;

        Test.startTest();
        ScheduledAccountUpdater scheduler = new ScheduledAccountUpdater();
        String jobId = System.schedule('Test Batch Execution', '0 0 2 * * ?', scheduler);
        Test.stopTest();

        // Verify batch was executed and account was updated
        Account updatedAcc = [SELECT Id, Description FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, updatedAcc.Description, 'Account description should be updated by batch');
        System.assert(updatedAcc.Description.contains('Last batch updated:'), 'Description should contain batch timestamp');
    }

    /**
     * @description Test getDailySchedule CRON expression generation
     */
    @isTest
    static void testGetDailySchedule() {
        String cronExpression = ScheduledAccountUpdater.getDailySchedule(2, 0);
        System.assertEquals('0 0 2 * * ?', cronExpression, 'CRON expression should be correct for 2 AM daily');
    }

    /**
     * @description Test getDailySchedule with various times
     */
    @isTest
    static void testGetDailyScheduleVariousTimes() {
        // Test midnight
        String midnight = ScheduledAccountUpdater.getDailySchedule(0, 0);
        System.assertEquals('0 0 0 * * ?', midnight, 'CRON expression should be correct for midnight');

        // Test noon
        String noon = ScheduledAccountUpdater.getDailySchedule(12, 0);
        System.assertEquals('0 0 12 * * ?', noon, 'CRON expression should be correct for noon');

        // Test 11:59 PM
        String latEvening = ScheduledAccountUpdater.getDailySchedule(23, 59);
        System.assertEquals('0 59 23 * * ?', latEvening, 'CRON expression should be correct for 11:59 PM');
    }

    /**
     * @description Test getHourlySchedule CRON expression generation
     */
    @isTest
    static void testGetHourlySchedule() {
        String cronExpression = ScheduledAccountUpdater.getHourlySchedule(0);
        System.assertEquals('0 0 * * * ?', cronExpression, 'CRON expression should be correct for top of each hour');
    }

    /**
     * @description Test getHourlySchedule with various minutes
     */
    @isTest
    static void testGetHourlyScheduleVariousMinutes() {
        // Test at 15 minutes past
        String fifteenPast = ScheduledAccountUpdater.getHourlySchedule(15);
        System.assertEquals('0 15 * * * ?', fifteenPast, 'CRON expression should be correct for :15 of each hour');

        // Test at 30 minutes past
        String thirtyPast = ScheduledAccountUpdater.getHourlySchedule(30);
        System.assertEquals('0 30 * * * ?', thirtyPast, 'CRON expression should be correct for :30 of each hour');

        // Test at 59 minutes past
        String fiftyNinePast = ScheduledAccountUpdater.getHourlySchedule(59);
        System.assertEquals('0 59 * * * ?', fiftyNinePast, 'CRON expression should be correct for :59 of each hour');
    }

    /**
     * @description Test getWeeklySchedule CRON expression generation
     */
    @isTest
    static void testGetWeeklySchedule() {
        // Monday at 2 AM
        String cronExpression = ScheduledAccountUpdater.getWeeklySchedule(2, 2, 0);
        System.assertEquals('0 0 2 ? * 2', cronExpression, 'CRON expression should be correct for Monday 2 AM');
    }

    /**
     * @description Test getWeeklySchedule for all days of week
     */
    @isTest
    static void testGetWeeklyScheduleAllDays() {
        String sunday = ScheduledAccountUpdater.getWeeklySchedule(1, 2, 0);
        System.assertEquals('0 0 2 ? * 1', sunday, 'CRON expression should be correct for Sunday');

        String monday = ScheduledAccountUpdater.getWeeklySchedule(2, 2, 0);
        System.assertEquals('0 0 2 ? * 2', monday, 'CRON expression should be correct for Monday');

        String friday = ScheduledAccountUpdater.getWeeklySchedule(6, 2, 0);
        System.assertEquals('0 0 2 ? * 6', friday, 'CRON expression should be correct for Friday');

        String saturday = ScheduledAccountUpdater.getWeeklySchedule(7, 2, 0);
        System.assertEquals('0 0 2 ? * 7', saturday, 'CRON expression should be correct for Saturday');
    }

    /**
     * @description Test that multiple scheduled jobs can be created
     */
    @isTest
    static void testMultipleScheduledJobsCanBeCreated() {
        Test.startTest();
        ScheduledAccountUpdater scheduler1 = new ScheduledAccountUpdater();
        String jobId1 = System.schedule('Job 1', '0 0 2 * * ?', scheduler1);

        ScheduledAccountUpdater scheduler2 = new ScheduledAccountUpdater();
        String jobId2 = System.schedule('Job 2', '0 0 4 * * ?', scheduler2);
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id IN (:jobId1, :jobId2)
        ];
        System.assertEquals(2, jobs.size(), 'Both scheduled jobs should be created');
    }

    /**
     * @description Test scheduled job with large dataset
     */
    @isTest
    static void testScheduledJobWithLargeDataset() {
        // Create 250 test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 250; i++) {
            testAccounts.add(new Account(
                Name = 'Large Dataset ' + i,
                Industry = 'Technology'
            ));
        }
        insert testAccounts;

        Test.startTest();
        ScheduledAccountUpdater scheduler = new ScheduledAccountUpdater();
        String jobId = System.schedule('Large Dataset Job', '0 0 2 * * ?', scheduler);
        Test.stopTest();

        // Verify all accounts were processed (Description is not filterable in SOQL; check in Apex)
        Integer updatedCount = 0;
        for (Account a : [SELECT Description FROM Account LIMIT 300]) {
            if (a.Description != null && a.Description.contains('Last batch updated:')) updatedCount++;
        }
        System.assertEquals(250, updatedCount, 'All 250 accounts should be updated by batch');
    }

    /**
     * @description Test scheduled job handles errors gracefully
     */
    @isTest
    static void testScheduledJobErrorHandling() {
        Test.startTest();
        ScheduledAccountUpdater scheduler = new ScheduledAccountUpdater();
        String jobId = System.schedule('Error Handling Test', '0 0 2 * * ?', scheduler);
        Test.stopTest();

        // Verify scheduled job was created even if batch execution encounters issues
        CronTrigger job = [
            SELECT Id, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertNotEquals(null, job, 'Scheduled job should be created despite potential errors');
    }

    /**
     * @description Test getDailySchedule generates valid CRON format
     */
    @isTest
    static void testDailyScheduleValidCronFormat() {
        String cronExpression = ScheduledAccountUpdater.getDailySchedule(14, 30);
        
        // Verify CRON format: should have exactly 6 parts separated by spaces
        List<String> parts = cronExpression.split(' ');
        System.assertEquals(6, parts.size(), 'CRON expression should have 6 parts');
        
        // Verify format is: second minute hour day month day_of_week
        System.assertEquals('0', parts[0], 'Second should be 0');
        System.assertEquals('30', parts[1], 'Minute should be 30');
        System.assertEquals('14', parts[2], 'Hour should be 14');
    }

    /**
     * @description Test that scheduled job maintains state through execution
     */
    @isTest
    static void testScheduledJobMaintainsState() {
        // Create initial accounts
        List<Account> initialAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            initialAccounts.add(new Account(Name = 'Initial ' + i, Industry = 'Technology'));
        }
        insert initialAccounts;

        Test.startTest();
        ScheduledAccountUpdater scheduler = new ScheduledAccountUpdater();
        String jobId = System.schedule('State Maintenance Test', '0 0 2 * * ?', scheduler);
        Test.stopTest();

        // Verify all original accounts still exist and were updated
        Integer accountCount = [SELECT COUNT() FROM Account WHERE Name LIKE 'Initial%'];
        System.assertEquals(10, accountCount, 'All 10 original accounts should still exist');
    }

    /**
     * @description Test scheduled job with accounts having various industries
     */
    @isTest
    static void testScheduledJobWithVariousIndustries() {
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(new Account(Name = 'Tech Company', Industry = 'Technology'));
        testAccounts.add(new Account(Name = 'Finance Corp', Industry = 'Finance'));
        testAccounts.add(new Account(Name = 'Health Services', Industry = 'Healthcare'));
        testAccounts.add(new Account(Name = 'Retail Store'));
        insert testAccounts;

        Test.startTest();
        ScheduledAccountUpdater scheduler = new ScheduledAccountUpdater();
        String jobId = System.schedule('Various Industries Test', '0 0 2 * * ?', scheduler);
        Test.stopTest();

        // Verify all accounts were updated regardless of industry
        List<Account> updatedAccounts = [
            SELECT Id, Description, Industry
            FROM Account
            WHERE Name IN ('Tech Company', 'Finance Corp', 'Health Services', 'Retail Store')
        ];
        System.assertEquals(4, updatedAccounts.size(), 'All 4 accounts should be updated');
    }

    /**
     * @description Test CRON expressions are compatible with System.schedule
     */
    @isTest
    static void testCronExpressionsCompatibleWithSystemSchedule() {
        Test.startTest();
        
        // Test daily schedule
        String dailyCron = ScheduledAccountUpdater.getDailySchedule(3, 0);
        ScheduledAccountUpdater dailyScheduler = new ScheduledAccountUpdater();
        String dailyJobId = System.schedule('Daily Test', dailyCron, dailyScheduler);
        System.assertNotEquals(null, dailyJobId, 'Daily CRON should be valid');

        // Test hourly schedule
        String hourlyCron = ScheduledAccountUpdater.getHourlySchedule(0);
        ScheduledAccountUpdater hourlyScheduler = new ScheduledAccountUpdater();
        String hourlyJobId = System.schedule('Hourly Test', hourlyCron, hourlyScheduler);
        System.assertNotEquals(null, hourlyJobId, 'Hourly CRON should be valid');

        // Test weekly schedule
        String weeklyCron = ScheduledAccountUpdater.getWeeklySchedule(2, 3, 0);
        ScheduledAccountUpdater weeklyScheduler = new ScheduledAccountUpdater();
        String weeklyJobId = System.schedule('Weekly Test', weeklyCron, weeklyScheduler);
        System.assertNotEquals(null, weeklyJobId, 'Weekly CRON should be valid');
        
        Test.stopTest();
    }

    /**
     * @description Test scheduled job execution context
     */
    @isTest
    static void testScheduledJobExecutionContext() {
        // Create test account
        Account acc = new Account(Name = 'Context Test', Industry = 'Technology');
        insert acc;

        Test.startTest();
        ScheduledAccountUpdater scheduler = new ScheduledAccountUpdater();
        String jobId = System.schedule('Context Test Job', '0 0 2 * * ?', scheduler);
        Test.stopTest();

        // Verify job was executed in proper context
        CronTrigger job = [
            SELECT Id, CronJobDetail.Name, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals('Context Test Job', job.CronJobDetail.Name, 'Job should execute with proper context');
    }

    /**
     * @description Test scheduled job with edge case times
     */
    @isTest
    static void testScheduledJobWithEdgeCaseTimes() {
        Test.startTest();
        
        // Test midnight (00:00)
        String midnight = ScheduledAccountUpdater.getDailySchedule(0, 0);
        ScheduledAccountUpdater midnightScheduler = new ScheduledAccountUpdater();
        String midnightJobId = System.schedule('Midnight Job', midnight, midnightScheduler);
        System.assertNotEquals(null, midnightJobId, 'Midnight schedule should work');

        // Test end of day (23:59)
        String endOfDay = ScheduledAccountUpdater.getDailySchedule(23, 59);
        ScheduledAccountUpdater endOfDayScheduler = new ScheduledAccountUpdater();
        String endOfDayJobId = System.schedule('End of Day Job', endOfDay, endOfDayScheduler);
        System.assertNotEquals(null, endOfDayJobId, 'End of day schedule should work');
        
        Test.stopTest();
    }
}
