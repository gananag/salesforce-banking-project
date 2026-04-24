/**
 * @description Test class for AccountRestService REST API.
 * Covers all HTTP verbs: GET, POST, PATCH, DELETE.
 * Reads results from RestContext.response.responseBody (void handler pattern).
 *
 * @author PD2 Project
 * @date 2026-04-24
 */
@IsTest
private class AccountRestServiceTest {

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private static void setupRestContext(String uri, String method, String body) {
        RestRequest  req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = uri;
        req.httpMethod = method;
        if (body != null) {
            req.requestBody = Blob.valueOf(body);
        }
        RestContext.request  = req;
        RestContext.response = res;
    }

    /**
     * Parses the JSON response body into a map for assertions.
     */
    private static Map<String, Object> getResponseMap() {
        Blob body = RestContext.response.responseBody;
        if (body == null) return new Map<String, Object>();
        return (Map<String, Object>) JSON.deserializeUntyped(body.toString());
    }

    private static Account createTestAccount(String name, String industry) {
        Account acc = new Account(Name = name, Industry = industry);
        insert acc;
        return acc;
    }

    // ─── GET Tests ────────────────────────────────────────────────────────────

    @IsTest
    static void testGetAllAccounts() {
        createTestAccount('Test Corp', 'Technology');
        createTestAccount('Acme Inc', 'Finance');

        setupRestContext('/services/apexrest/accounts/', 'GET', null);

        Test.startTest();
        AccountRestService.doGet();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(true, (Boolean) resp.get('success'));
        System.assertEquals(200, (Integer) resp.get('statusCode'));
        System.assertNotEquals(null, resp.get('data'));
    }

    @IsTest
    static void testGetAccountsByIndustry() {
        createTestAccount('Tech Alpha', 'Technology');
        createTestAccount('Tech Beta',  'Technology');
        createTestAccount('Finance Co', 'Finance');

        setupRestContext('/services/apexrest/accounts/', 'GET', null);
        RestContext.request.params.put('industry', 'Technology');

        Test.startTest();
        AccountRestService.doGet();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(true, (Boolean) resp.get('success'));
        System.assertEquals(200, (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testGetSingleAccountById() {
        Account acc = createTestAccount('Single Corp', 'Healthcare');

        setupRestContext('/services/apexrest/accounts/' + acc.Id, 'GET', null);

        Test.startTest();
        AccountRestService.doGet();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(true,  (Boolean) resp.get('success'));
        System.assertEquals(200,   (Integer) resp.get('statusCode'));
        System.assertNotEquals(null, resp.get('data'));
    }

    @IsTest
    static void testGetSingleAccount_NotFound() {
        setupRestContext('/services/apexrest/accounts/001000000000000AAA', 'GET', null);

        Test.startTest();
        AccountRestService.doGet();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(404,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testExtractIdFromUrl_NoId() {
        String result = AccountRestService.extractIdFromUrl('/services/apexrest/accounts/');
        System.assertEquals('', result);
    }

    @IsTest
    static void testExtractIdFromUrl_BlankUri() {
        String result = AccountRestService.extractIdFromUrl('');
        System.assertEquals('', result);
    }

    // ─── POST Tests ───────────────────────────────────────────────────────────

    @IsTest
    static void testPostCreateAccount_Success() {
        String body = JSON.serialize(new Map<String, Object>{
            'name'     => 'New REST Account',
            'industry' => 'Technology',
            'phone'    => '555-1234',
            'website'  => 'https://newrestaccount.example.com'
        });

        setupRestContext('/services/apexrest/accounts/', 'POST', body);

        Test.startTest();
        AccountRestService.doPost();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(true, (Boolean) resp.get('success'), String.valueOf(resp.get('message')));
        System.assertEquals(201,  (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPostCreateAccount_MissingName() {
        String body = JSON.serialize(new Map<String, Object>{'industry' => 'Technology'});
        setupRestContext('/services/apexrest/accounts/', 'POST', body);

        Test.startTest();
        AccountRestService.doPost();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(400,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPostCreateAccount_MissingIndustry() {
        String body = JSON.serialize(new Map<String, Object>{'name' => 'No Industry Corp'});
        setupRestContext('/services/apexrest/accounts/', 'POST', body);

        Test.startTest();
        AccountRestService.doPost();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(400,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPostCreateAccount_DuplicateName() {
        createTestAccount('Duplicate Corp', 'Technology');

        String body = JSON.serialize(new Map<String, Object>{
            'name'     => 'Duplicate Corp',
            'industry' => 'Technology'
        });
        setupRestContext('/services/apexrest/accounts/', 'POST', body);

        Test.startTest();
        AccountRestService.doPost();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(409,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPostCreateAccount_InvalidJson() {
        setupRestContext('/services/apexrest/accounts/', 'POST', 'NOT_VALID_JSON{{{');

        Test.startTest();
        AccountRestService.doPost();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        Integer sc = (Integer) resp.get('statusCode');
        System.assert(sc == 400 || sc == 500, 'Expected error status, got: ' + sc);
    }

    // ─── PATCH Tests ──────────────────────────────────────────────────────────

    @IsTest
    static void testPatchUpdateRevenue_Success() {
        Account acc = createTestAccount('Patch Corp', 'Finance');

        String body = JSON.serialize(new Map<String, Object>{'annualRevenue' => 5000000});
        setupRestContext('/services/apexrest/accounts/' + acc.Id, 'PATCH', body);

        Test.startTest();
        AccountRestService.doPatch();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(true, (Boolean) resp.get('success'), String.valueOf(resp.get('message')));
        System.assertEquals(200,  (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPatchUpdatePhoneAndWebsite_Success() {
        Account acc = createTestAccount('Phone Corp', 'Healthcare');

        String body = JSON.serialize(new Map<String, Object>{
            'phone'   => '555-9999',
            'website' => 'https://phonecorp.example.com'
        });
        setupRestContext('/services/apexrest/accounts/' + acc.Id, 'PATCH', body);

        Test.startTest();
        AccountRestService.doPatch();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(true, (Boolean) resp.get('success'));
        System.assertEquals(200,  (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPatch_NegativeRevenue() {
        Account acc = createTestAccount('Negative Corp', 'Retail');

        String body = JSON.serialize(new Map<String, Object>{'annualRevenue' => -100});
        setupRestContext('/services/apexrest/accounts/' + acc.Id, 'PATCH', body);

        Test.startTest();
        AccountRestService.doPatch();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(400,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPatch_NoIdInUrl() {
        String body = JSON.serialize(new Map<String, Object>{'annualRevenue' => 1000});
        setupRestContext('/services/apexrest/accounts/', 'PATCH', body);

        Test.startTest();
        AccountRestService.doPatch();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(400,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPatch_AccountNotFound() {
        String body = JSON.serialize(new Map<String, Object>{'annualRevenue' => 1000});
        setupRestContext('/services/apexrest/accounts/001000000000000AAA', 'PATCH', body);

        Test.startTest();
        AccountRestService.doPatch();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(404,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPatch_NoUpdateableFields() {
        Account acc = createTestAccount('Empty Patch Corp', 'Energy');

        String body = JSON.serialize(new Map<String, Object>{'unknownField' => 'value'});
        setupRestContext('/services/apexrest/accounts/' + acc.Id, 'PATCH', body);

        Test.startTest();
        AccountRestService.doPatch();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(400,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testPatch_InvalidJson() {
        Account acc = createTestAccount('Bad JSON Corp', 'Media');
        setupRestContext('/services/apexrest/accounts/' + acc.Id, 'PATCH', '{{INVALID}}');

        Test.startTest();
        AccountRestService.doPatch();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        Integer sc = (Integer) resp.get('statusCode');
        System.assert(sc == 400 || sc == 500);
    }

    // ─── DELETE Tests ─────────────────────────────────────────────────────────

    @IsTest
    static void testDeleteAccount_Success() {
        Account acc = createTestAccount('Delete Me Corp', 'Agriculture');
        setupRestContext('/services/apexrest/accounts/' + acc.Id, 'DELETE', null);

        Test.startTest();
        AccountRestService.doDelete();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(true, (Boolean) resp.get('success'), String.valueOf(resp.get('message')));
        System.assertEquals(200,  (Integer) resp.get('statusCode'));

        List<Account> remaining = [SELECT Id FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, remaining.size(), 'Account should be deleted');
    }

    @IsTest
    static void testDelete_NoIdInUrl() {
        setupRestContext('/services/apexrest/accounts/', 'DELETE', null);

        Test.startTest();
        AccountRestService.doDelete();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(400,   (Integer) resp.get('statusCode'));
    }

    @IsTest
    static void testDelete_AccountNotFound() {
        setupRestContext('/services/apexrest/accounts/001000000000000AAA', 'DELETE', null);

        Test.startTest();
        AccountRestService.doDelete();
        Test.stopTest();

        Map<String, Object> resp = getResponseMap();
        System.assertEquals(false, (Boolean) resp.get('success'));
        System.assertEquals(404,   (Integer) resp.get('statusCode'));
    }

    // ─── ResponseWrapper Tests ────────────────────────────────────────────────

    @IsTest
    static void testResponseWrapperConstruction() {
        AccountRestService.ResponseWrapper wrapper =
            new AccountRestService.ResponseWrapper(true, 'OK', 'someData', 200);

        System.assertEquals(true,       wrapper.success);
        System.assertEquals('OK',       wrapper.message);
        System.assertEquals('someData', wrapper.data);
        System.assertEquals(200,        wrapper.statusCode);
    }
}
