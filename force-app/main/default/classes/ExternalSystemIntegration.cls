/**
 * @description External system integration service.
 * Demonstrates HTTP callout patterns for PD2 exam: HttpRequest, HttpResponse,
 * HttpCalloutMock, Named Credentials, and error handling for callouts.
 *
 * Simulates integration with a fictitious external CRM/ERP endpoint.
 * In production, replace ENDPOINT_BASE with a Named Credential:
 *   callout:External_CRM/api/accounts
 *
 * @author PD2 Project
 * @date 2026-04-24
 */
public with sharing class ExternalSystemIntegration {

    // Replace with Named Credential in production: 'callout:External_CRM'
    @TestVisible
    private static final String ENDPOINT_BASE = 'https://external-crm.example.com/api';

    private static final Integer TIMEOUT_MS   = 10000; // 10 seconds
    private static final String  CONTENT_TYPE = 'application/json';

    // ─── Inner Classes ────────────────────────────────────────────────────────

    /**
     * @description Represents an account record from the external system.
     */
    public class ExternalAccount {
        public String  externalId;
        public String  name;
        public String  industry;
        public Decimal revenue;
        public String  status;

        public ExternalAccount() {}

        public ExternalAccount(String externalId, String name, String industry, Decimal revenue, String status) {
            this.externalId = externalId;
            this.name       = name;
            this.industry   = industry;
            this.revenue    = revenue;
            this.status     = status;
        }
    }

    /**
     * @description Represents the result of a callout operation.
     */
    public class CalloutResult {
        public Boolean success;
        public Integer statusCode;
        public String  message;
        public Object  data;

        public CalloutResult(Boolean success, Integer statusCode, String message, Object data) {
            this.success    = success;
            this.statusCode = statusCode;
            this.message    = message;
            this.data       = data;
        }
    }

    // ─── Public Methods ───────────────────────────────────────────────────────

    /**
     * @description Syncs a Salesforce Account to the external CRM via HTTP POST.
     * Pulls the Account from Salesforce, serializes it, and POSTs to the external endpoint.
     *
     * @param accountId Salesforce Account ID to sync
     * @return CalloutResult with external system response
     */
    public static CalloutResult syncAccountToExternal(Id accountId) {
        if (accountId == null) {
            return new CalloutResult(false, 400, 'Account ID is required.', null);
        }

        List<Account> accounts = [
            SELECT Id, Name, Industry, AnnualRevenue, Phone, Website
            FROM Account
            WHERE Id = :accountId
            LIMIT 1
        ];

        if (accounts.isEmpty()) {
            return new CalloutResult(false, 404, 'Account not found in Salesforce.', null);
        }

        Account acc = accounts[0];

        Map<String, Object> payload = new Map<String, Object>{
            'salesforceId' => acc.Id,
            'name'         => acc.Name,
            'industry'     => acc.Industry,
            'revenue'      => acc.AnnualRevenue,
            'phone'        => acc.Phone,
            'website'      => acc.Website
        };

        HttpRequest req = buildRequest('POST', ENDPOINT_BASE + '/accounts', JSON.serialize(payload));

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                return new CalloutResult(true, res.getStatusCode(), 'Account synced to external system.', res.getBody());
            } else {
                return new CalloutResult(false, res.getStatusCode(), 'External system returned error: ' + res.getStatus(), res.getBody());
            }

        } catch (CalloutException e) {
            return new CalloutResult(false, 503, 'Callout failed: ' + e.getMessage(), null);
        }
    }

    /**
     * @description Fetches a list of accounts from the external CRM via HTTP GET.
     * Optionally filters by industry.
     *
     * @param industry Optional industry filter (null = all)
     * @return CalloutResult with list of ExternalAccount objects in data field
     */
    public static CalloutResult fetchExternalAccounts(String industry) {
        String url = ENDPOINT_BASE + '/accounts';
        if (String.isNotBlank(industry)) {
            url += '?industry=' + EncodingUtil.urlEncode(industry, 'UTF-8');
        }

        HttpRequest req = buildRequest('GET', url, null);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                List<ExternalAccount> externalAccounts = parseExternalAccounts(res.getBody());
                return new CalloutResult(true, 200, externalAccounts.size() + ' account(s) fetched from external system.', externalAccounts);
            } else {
                return new CalloutResult(false, res.getStatusCode(), 'External system returned: ' + res.getStatus(), null);
            }

        } catch (CalloutException e) {
            return new CalloutResult(false, 503, 'Callout failed: ' + e.getMessage(), null);
        }
    }

    /**
     * @description Updates an account in the external system via HTTP PUT.
     *
     * @param externalId  The ID of the record in the external system
     * @param accountData Map of fields to update
     * @return CalloutResult
     */
    public static CalloutResult updateExternalAccount(String externalId, Map<String, Object> accountData) {
        if (String.isBlank(externalId)) {
            return new CalloutResult(false, 400, 'External ID is required.', null);
        }
        if (accountData == null || accountData.isEmpty()) {
            return new CalloutResult(false, 400, 'Account data is required.', null);
        }

        HttpRequest req = buildRequest('PUT', ENDPOINT_BASE + '/accounts/' + externalId, JSON.serialize(accountData));

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200) {
                return new CalloutResult(true, 200, 'External account updated.', res.getBody());
            } else {
                return new CalloutResult(false, res.getStatusCode(), 'Update failed: ' + res.getStatus(), res.getBody());
            }

        } catch (CalloutException e) {
            return new CalloutResult(false, 503, 'Callout failed: ' + e.getMessage(), null);
        }
    }

    /**
     * @description Deletes an account from the external system via HTTP DELETE.
     *
     * @param externalId The ID of the record in the external system
     * @return CalloutResult
     */
    public static CalloutResult deleteExternalAccount(String externalId) {
        if (String.isBlank(externalId)) {
            return new CalloutResult(false, 400, 'External ID is required.', null);
        }

        HttpRequest req = buildRequest('DELETE', ENDPOINT_BASE + '/accounts/' + externalId, null);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() == 200 || res.getStatusCode() == 204) {
                return new CalloutResult(true, res.getStatusCode(), 'External account deleted.', null);
            } else {
                return new CalloutResult(false, res.getStatusCode(), 'Delete failed: ' + res.getStatus(), res.getBody());
            }

        } catch (CalloutException e) {
            return new CalloutResult(false, 503, 'Callout failed: ' + e.getMessage(), null);
        }
    }

    /**
     * @description Checks external system health/availability via HTTP GET.
     *
     * @return true if external system is reachable and healthy
     */
    public static Boolean isExternalSystemAvailable() {
        HttpRequest req = buildRequest('GET', ENDPOINT_BASE + '/health', null);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            return res.getStatusCode() == 200;
        } catch (CalloutException e) {
            return false;
        }
    }

    // ─── Private Helpers ──────────────────────────────────────────────────────

    /**
     * @description Builds a reusable HttpRequest with standard headers.
     */
    private static HttpRequest buildRequest(String method, String endpoint, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setTimeout(TIMEOUT_MS);
        req.setHeader('Content-Type', CONTENT_TYPE);
        req.setHeader('Accept', CONTENT_TYPE);
        // In production: req.setHeader('Authorization', 'Bearer ' + getToken());
        if (body != null) {
            req.setBody(body);
        }
        return req;
    }

    /**
     * @description Parses a JSON array of external accounts into ExternalAccount objects.
     */
    @TestVisible
    private static List<ExternalAccount> parseExternalAccounts(String jsonBody) {
        List<ExternalAccount> result = new List<ExternalAccount>();
        if (String.isBlank(jsonBody)) return result;

        try {
            List<Object> raw = (List<Object>) JSON.deserializeUntyped(jsonBody);
            for (Object item : raw) {
                Map<String, Object> record = (Map<String, Object>) item;
                ExternalAccount ea = new ExternalAccount();
                ea.externalId = (String)  record.get('id');
                ea.name       = (String)  record.get('name');
                ea.industry   = (String)  record.get('industry');
                ea.status     = (String)  record.get('status');
                if (record.get('revenue') != null) {
                    ea.revenue = Decimal.valueOf(String.valueOf(record.get('revenue')));
                }
                result.add(ea);
            }
        } catch (Exception e) {
            // Return whatever was parsed; caller handles empty list
            System.debug(LoggingLevel.WARN, 'parseExternalAccounts error: ' + e.getMessage());
        }

        return result;
    }
}
