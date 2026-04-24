/**
 * @description Test class for ExternalSystemIntegration.
 * Uses HttpCalloutMock to simulate external system responses.
 * Covers success, error, and edge-case branches.
 *
 * PD2 concepts: HttpCalloutMock, Test.setMock(), callout patterns.
 *
 * @author PD2 Project
 * @date 2026-04-24
 */
@IsTest
private class ExternalSystemIntegrationTest {

    // ─── Mock Implementations ─────────────────────────────────────────────────

    /**
     * @description Generic mock that returns a configurable status + body.
     */
    private class ConfigurableMock implements HttpCalloutMock {
        private Integer statusCode;
        private String  body;
        private String  status;

        ConfigurableMock(Integer statusCode, String status, String body) {
            this.statusCode = statusCode;
            this.status     = status;
            this.body       = body;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setStatus(status);
            res.setBody(body != null ? body : '');
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }

    /**
     * @description Mock that throws a CalloutException to simulate network failure.
     */
    private class FailingMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated network failure');
        }
    }

    // ─── syncAccountToExternal Tests ─────────────────────────────────────────

    @IsTest
    static void testSyncAccount_Success() {
        Account acc = new Account(Name = 'Sync Test Corp', Industry = 'Technology');
        insert acc;

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(201, 'Created', '{"id":"ext-001","status":"synced"}'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.syncAccountToExternal(acc.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, result.message);
        System.assertEquals(201, result.statusCode);
    }

    @IsTest
    static void testSyncAccount_200Response() {
        Account acc = new Account(Name = 'Sync 200 Corp', Industry = 'Finance');
        insert acc;

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, 'OK', '{"id":"ext-002","status":"updated"}'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.syncAccountToExternal(acc.Id);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(200, result.statusCode);
    }

    @IsTest
    static void testSyncAccount_ExternalError() {
        Account acc = new Account(Name = 'Sync Error Corp', Industry = 'Healthcare');
        insert acc;

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(500, 'Internal Server Error', '{"error":"Server fault"}'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.syncAccountToExternal(acc.Id);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(500, result.statusCode);
    }

    @IsTest
    static void testSyncAccount_NullId() {
        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.syncAccountToExternal(null);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(400, result.statusCode);
    }

    @IsTest
    static void testSyncAccount_AccountNotFound() {
        // Valid format but non-existent
        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.syncAccountToExternal('001000000000000AAA');
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(404, result.statusCode);
    }

    @IsTest
    static void testSyncAccount_CalloutException() {
        Account acc = new Account(Name = 'Network Fail Corp', Industry = 'Retail');
        insert acc;

        Test.setMock(HttpCalloutMock.class, new FailingMock());

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.syncAccountToExternal(acc.Id);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(503, result.statusCode);
        System.assert(result.message.contains('Callout failed'));
    }

    // ─── fetchExternalAccounts Tests ─────────────────────────────────────────

    @IsTest
    static void testFetchExternalAccounts_Success() {
        String mockBody = JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{'id' => 'ext-001', 'name' => 'External Corp A', 'industry' => 'Technology', 'revenue' => 500000, 'status' => 'active'},
            new Map<String, Object>{'id' => 'ext-002', 'name' => 'External Corp B', 'industry' => 'Technology', 'revenue' => 1000000, 'status' => 'active'}
        });

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, 'OK', mockBody));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.fetchExternalAccounts('Technology');
        Test.stopTest();

        System.assertEquals(true, result.success, result.message);
        System.assertEquals(200, result.statusCode);
        List<ExternalSystemIntegration.ExternalAccount> accounts =
            (List<ExternalSystemIntegration.ExternalAccount>) result.data;
        System.assertEquals(2, accounts.size());
        System.assertEquals('External Corp A', accounts[0].name);
    }

    @IsTest
    static void testFetchExternalAccounts_NoFilter() {
        String mockBody = JSON.serialize(new List<Map<String, Object>>{
            new Map<String, Object>{'id' => 'ext-003', 'name' => 'All Industries Corp', 'industry' => 'Finance', 'revenue' => 250000, 'status' => 'active'}
        });

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, 'OK', mockBody));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.fetchExternalAccounts(null);
        Test.stopTest();

        System.assertEquals(true, result.success);
    }

    @IsTest
    static void testFetchExternalAccounts_NotFound() {
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(404, 'Not Found', '{"error":"No accounts found"}'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.fetchExternalAccounts('UnknownIndustry');
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(404, result.statusCode);
    }

    @IsTest
    static void testFetchExternalAccounts_CalloutException() {
        Test.setMock(HttpCalloutMock.class, new FailingMock());

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.fetchExternalAccounts('Technology');
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(503, result.statusCode);
    }

    @IsTest
    static void testFetchExternalAccounts_EmptyBody() {
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, 'OK', '[]'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.fetchExternalAccounts('EmptyIndustry');
        Test.stopTest();

        System.assertEquals(true, result.success);
        List<ExternalSystemIntegration.ExternalAccount> accounts =
            (List<ExternalSystemIntegration.ExternalAccount>) result.data;
        System.assertEquals(0, accounts.size());
    }

    // ─── updateExternalAccount Tests ──────────────────────────────────────────

    @IsTest
    static void testUpdateExternalAccount_Success() {
        Map<String, Object> data = new Map<String, Object>{'revenue' => 999999, 'status' => 'premium'};

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, 'OK', '{"status":"updated"}'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.updateExternalAccount('ext-001', data);
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(200, result.statusCode);
    }

    @IsTest
    static void testUpdateExternalAccount_BlankId() {
        Map<String, Object> data = new Map<String, Object>{'revenue' => 100};

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.updateExternalAccount('', data);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(400, result.statusCode);
    }

    @IsTest
    static void testUpdateExternalAccount_NullData() {
        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.updateExternalAccount('ext-001', null);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(400, result.statusCode);
    }

    @IsTest
    static void testUpdateExternalAccount_ExternalError() {
        Map<String, Object> data = new Map<String, Object>{'revenue' => 100};

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(422, 'Unprocessable Entity', '{"error":"Validation failed"}'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.updateExternalAccount('ext-999', data);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(422, result.statusCode);
    }

    @IsTest
    static void testUpdateExternalAccount_CalloutException() {
        Map<String, Object> data = new Map<String, Object>{'revenue' => 100};

        Test.setMock(HttpCalloutMock.class, new FailingMock());

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.updateExternalAccount('ext-001', data);
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(503, result.statusCode);
    }

    // ─── deleteExternalAccount Tests ──────────────────────────────────────────

    @IsTest
    static void testDeleteExternalAccount_Success200() {
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, 'OK', '{"status":"deleted"}'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.deleteExternalAccount('ext-001');
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(200, result.statusCode);
    }

    @IsTest
    static void testDeleteExternalAccount_Success204() {
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(204, 'No Content', ''));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.deleteExternalAccount('ext-002');
        Test.stopTest();

        System.assertEquals(true, result.success);
        System.assertEquals(204, result.statusCode);
    }

    @IsTest
    static void testDeleteExternalAccount_BlankId() {
        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.deleteExternalAccount('');
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(400, result.statusCode);
    }

    @IsTest
    static void testDeleteExternalAccount_NotFound() {
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(404, 'Not Found', '{"error":"Not found"}'));

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.deleteExternalAccount('ext-999');
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(404, result.statusCode);
    }

    @IsTest
    static void testDeleteExternalAccount_CalloutException() {
        Test.setMock(HttpCalloutMock.class, new FailingMock());

        Test.startTest();
        ExternalSystemIntegration.CalloutResult result = ExternalSystemIntegration.deleteExternalAccount('ext-001');
        Test.stopTest();

        System.assertEquals(false, result.success);
        System.assertEquals(503, result.statusCode);
    }

    // ─── isExternalSystemAvailable Tests ─────────────────────────────────────

    @IsTest
    static void testIsExternalSystemAvailable_True() {
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, 'OK', '{"status":"healthy"}'));

        Test.startTest();
        Boolean available = ExternalSystemIntegration.isExternalSystemAvailable();
        Test.stopTest();

        System.assertEquals(true, available);
    }

    @IsTest
    static void testIsExternalSystemAvailable_False_503() {
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(503, 'Service Unavailable', ''));

        Test.startTest();
        Boolean available = ExternalSystemIntegration.isExternalSystemAvailable();
        Test.stopTest();

        System.assertEquals(false, available);
    }

    @IsTest
    static void testIsExternalSystemAvailable_False_Exception() {
        Test.setMock(HttpCalloutMock.class, new FailingMock());

        Test.startTest();
        Boolean available = ExternalSystemIntegration.isExternalSystemAvailable();
        Test.stopTest();

        System.assertEquals(false, available);
    }

    // ─── parseExternalAccounts Tests ─────────────────────────────────────────

    @IsTest
    static void testParseExternalAccounts_ValidJson() {
        String json = '[{"id":"e1","name":"A","industry":"Tech","revenue":100000,"status":"active"}]';

        Test.startTest();
        List<ExternalSystemIntegration.ExternalAccount> accounts =
            ExternalSystemIntegration.parseExternalAccounts(json);
        Test.stopTest();

        System.assertEquals(1, accounts.size());
        System.assertEquals('e1', accounts[0].externalId);
        System.assertEquals(100000, accounts[0].revenue);
    }

    @IsTest
    static void testParseExternalAccounts_NullRevenue() {
        String json = '[{"id":"e2","name":"B","industry":"Finance","status":"inactive"}]';

        Test.startTest();
        List<ExternalSystemIntegration.ExternalAccount> accounts =
            ExternalSystemIntegration.parseExternalAccounts(json);
        Test.stopTest();

        System.assertEquals(1, accounts.size());
        System.assertEquals(null, accounts[0].revenue);
    }

    @IsTest
    static void testParseExternalAccounts_BlankBody() {
        Test.startTest();
        List<ExternalSystemIntegration.ExternalAccount> accounts =
            ExternalSystemIntegration.parseExternalAccounts('');
        Test.stopTest();

        System.assertEquals(0, accounts.size());
    }

    // ─── CalloutResult Inner Class ─────────────────────────────────────────────

    @IsTest
    static void testCalloutResultConstruction() {
        ExternalSystemIntegration.CalloutResult result =
            new ExternalSystemIntegration.CalloutResult(true, 200, 'OK', 'some data');

        System.assertEquals(true, result.success);
        System.assertEquals(200, result.statusCode);
        System.assertEquals('OK', result.message);
        System.assertEquals('some data', result.data);
    }

    // ─── ExternalAccount Inner Class ─────────────────────────────────────────

    @IsTest
    static void testExternalAccountConstruction() {
        ExternalSystemIntegration.ExternalAccount ea =
            new ExternalSystemIntegration.ExternalAccount('ext-1', 'Test', 'Tech', 500000, 'active');

        System.assertEquals('ext-1', ea.externalId);
        System.assertEquals('Test', ea.name);
        System.assertEquals('Tech', ea.industry);
        System.assertEquals(500000, ea.revenue);
        System.assertEquals('active', ea.status);
    }
}
