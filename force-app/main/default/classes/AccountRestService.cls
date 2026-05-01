/**
 * @description REST API service for Account CRUD operations.
 * Exposes endpoints under /services/apexrest/accounts/*
 *
 * Endpoints:
 *   GET    /accounts/           - List accounts (query param: industry)
 *   GET    /accounts/{id}       - Get single account by ID
 *   POST   /accounts/           - Create account (body: name, industry, phone, website)
 *   PATCH  /accounts/{id}       - Update fields (body: annualRevenue, phone, website)
 *   DELETE /accounts/{id}       - Delete account
 *
 * @author PD2 Project
 * @date 2026-04-24
 */
@RestResource(urlMapping='/accounts/*')
global with sharing class AccountRestService {

    /**
     * @description Wrapper for all REST responses — serialized to JSON in the response body.
     */
    global class ResponseWrapper {
        global Boolean success;
        global String  message;
        global Object  data;
        global Integer statusCode;

        global ResponseWrapper(Boolean success, String message, Object data, Integer statusCode) {
            this.success    = success;
            this.message    = message;
            this.data       = data;
            this.statusCode = statusCode;
        }
    }

    // ─── HTTP Handlers ────────────────────────────────────────────────────────

    /**
     * @description GET handler.
     * - With ID in URL  : returns single Account by Id
     * - Without ID      : returns list of Accounts filtered by ?industry= query param
     */
    @HttpGet
    global static void doGet() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            if (!Account.sObjectType.getDescribe().isAccessible()) {
                sendResponse(res, 403, false, 'Insufficient permissions to read Account records.', null);
                return;
            }

            String accountId = extractIdFromUrl(req.requestURI);

            if (String.isNotBlank(accountId)) {
                List<Account> accounts = [
                    SELECT Id, Name, Industry, Type, AnnualRevenue, Phone, Website, OwnerId
                    FROM Account
                    WHERE Id = :accountId
                    LIMIT 1
                ];

                if (accounts.isEmpty()) {
                    sendResponse(res, 404, false, 'Account not found.', null);
                    return;
                }

                sendResponse(res, 200, true, 'Account retrieved successfully.', accounts[0]);

            } else {
                String industry = req.params.get('industry');

                List<Account> accounts;
                if (String.isNotBlank(industry)) {
                    accounts = [
                        SELECT Id, Name, Industry, Type, AnnualRevenue, Phone, Website
                        FROM Account
                        WHERE Industry = :industry
                        ORDER BY Name
                        LIMIT 200
                    ];
                } else {
                    accounts = [
                        SELECT Id, Name, Industry, Type, AnnualRevenue, Phone, Website
                        FROM Account
                        ORDER BY Name
                        LIMIT 200
                    ];
                }

                sendResponse(res, 200, true, accounts.size() + ' account(s) retrieved.', accounts);
            }

        } catch (Exception e) {
            sendResponse(res, 500, false, 'Error: ' + e.getMessage(), null);
        }
    }

    /**
     * @description POST handler — creates a new Account.
     * Expected JSON body: { "name": "...", "industry": "...", "phone": "...", "website": "..." }
     */
    @HttpPost
    global static void doPost() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            if (!Account.sObjectType.getDescribe().isCreateable()) {
                sendResponse(res, 403, false, 'Insufficient permissions to create Account records.', null);
                return;
            }

            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            String name     = (String) body.get('name');
            String industry = (String) body.get('industry');
            String phone    = (String) body.get('phone');
            String website  = (String) body.get('website');

            if (String.isBlank(name)) {
                sendResponse(res, 400, false, 'Account name is required.', null);
                return;
            }
            if (String.isBlank(industry)) {
                sendResponse(res, 400, false, 'Industry is required.', null);
                return;
            }

            List<Account> existing = [SELECT Id FROM Account WHERE Name = :name LIMIT 1];
            if (!existing.isEmpty()) {
                sendResponse(res, 409, false, 'An account with this name already exists.', null);
                return;
            }

            Account acc = new Account(Name = name, Industry = industry);
            if (String.isNotBlank(phone))   acc.Phone   = phone;
            if (String.isNotBlank(website)) acc.Website = website;

            insert acc;

            Account created = [
                SELECT Id, Name, Industry, Type, AnnualRevenue, Phone, Website, OwnerId, CreatedDate
                FROM Account
                WHERE Id = :acc.Id
            ];

            sendResponse(res, 201, true, 'Account created successfully.', created);

        } catch (JSONException e) {
            sendResponse(res, 400, false, 'Invalid JSON body: ' + e.getMessage(), null);
        } catch (DmlException e) {
            sendResponse(res, 422, false, 'DML error: ' + e.getDmlMessage(0), null);
        } catch (Exception e) {
            sendResponse(res, 500, false, 'Error: ' + e.getMessage(), null);
        }
    }

    /**
     * @description PATCH handler — updates fields on an existing Account.
     * URL must contain account ID: /accounts/{id}
     * Expected JSON body: { "annualRevenue": 1000000, "phone": "...", "website": "..." }
     */
    @HttpPatch
    global static void doPatch() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            if (!Account.sObjectType.getDescribe().isUpdateable()) {
                sendResponse(res, 403, false, 'Insufficient permissions to update Account records.', null);
                return;
            }

            String accountId = extractIdFromUrl(req.requestURI);
            if (String.isBlank(accountId)) {
                sendResponse(res, 400, false, 'Account ID must be provided in the URL.', null);
                return;
            }

            List<Account> accounts = [SELECT Id, Name, AnnualRevenue, Phone, Website FROM Account WHERE Id = :accountId LIMIT 1];
            if (accounts.isEmpty()) {
                sendResponse(res, 404, false, 'Account not found.', null);
                return;
            }

            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());

            Account acc = accounts[0];
            Boolean updated = false;

            if (body.containsKey('annualRevenue')) {
                Decimal revenue = Decimal.valueOf(String.valueOf(body.get('annualRevenue')));
                if (revenue < 0) {
                    sendResponse(res, 400, false, 'Annual revenue cannot be negative.', null);
                    return;
                }
                acc.AnnualRevenue = revenue;
                updated = true;
            }

            if (body.containsKey('phone')) {
                acc.Phone = (String) body.get('phone');
                updated = true;
            }

            if (body.containsKey('website')) {
                acc.Website = (String) body.get('website');
                updated = true;
            }

            if (!updated) {
                sendResponse(res, 400, false, 'No updatable fields provided in request body.', null);
                return;
            }

            update acc;

            Account patched = [
                SELECT Id, Name, Industry, Type, AnnualRevenue, Phone, Website, LastModifiedDate
                FROM Account
                WHERE Id = :acc.Id
            ];

            sendResponse(res, 200, true, 'Account updated successfully.', patched);

        } catch (JSONException e) {
            sendResponse(res, 400, false, 'Invalid JSON body: ' + e.getMessage(), null);
        } catch (DmlException e) {
            sendResponse(res, 422, false, 'DML error: ' + e.getDmlMessage(0), null);
        } catch (Exception e) {
            sendResponse(res, 500, false, 'Error: ' + e.getMessage(), null);
        }
    }

    /**
     * @description DELETE handler — deletes an Account by ID in the URL.
     */
    @HttpDelete
    global static void doDelete() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            if (!Account.sObjectType.getDescribe().isDeletable()) {
                sendResponse(res, 403, false, 'Insufficient permissions to delete Account records.', null);
                return;
            }

            String accountId = extractIdFromUrl(req.requestURI);
            if (String.isBlank(accountId)) {
                sendResponse(res, 400, false, 'Account ID must be provided in the URL.', null);
                return;
            }

            List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id = :accountId LIMIT 1];
            if (accounts.isEmpty()) {
                sendResponse(res, 404, false, 'Account not found.', null);
                return;
            }

            String deletedName = accounts[0].Name;
            delete accounts[0];

            sendResponse(res, 200, true, 'Account "' + deletedName + '" deleted successfully.', null);

        } catch (DmlException e) {
            sendResponse(res, 422, false, 'DML error: ' + e.getDmlMessage(0), null);
        } catch (Exception e) {
            sendResponse(res, 500, false, 'Error: ' + e.getMessage(), null);
        }
    }

    // ─── Private Helpers ──────────────────────────────────────────────────────

    /**
     * @description Serializes a ResponseWrapper to JSON and writes it to the REST response.
     */
    private static void sendResponse(RestResponse res, Integer statusCode, Boolean success, String message, Object data) {
        res.statusCode    = statusCode;
        res.addHeader('Content-Type', 'application/json');
        res.responseBody  = Blob.valueOf(JSON.serialize(new ResponseWrapper(success, message, data, statusCode)));
    }

    /**
     * @description Extracts a Salesforce record ID from the end of a REST URL.
     * e.g. /services/apexrest/accounts/001xx000003GYkVAAW -> 001xx000003GYkVAAW
     */
    @TestVisible
    private static String extractIdFromUrl(String requestURI) {
        if (String.isBlank(requestURI)) return '';
        List<String> parts = requestURI.split('/');
        String last = parts[parts.size() - 1];
        if (last.length() == 15 || last.length() == 18) {
            return last;
        }
        return '';
    }
}
