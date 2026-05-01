# Salesforce Banking CRM — Apex | LWC | SFDX

A production-grade Salesforce implementation for a banking domain CRM — covering full-stack development with Apex, Lightning Web Components, REST APIs, async processing, and enterprise security patterns.

## What Was Built

### Account Management Platform
End-to-end account lifecycle management for banking customers, built with best-practice Salesforce architecture:

- **Lightning Web Component UI** — searchable, paginated account datatable with inline create/edit modals, real-time industry filtering, and revenue update flows
- **Apex Service Layer** — `AccountManager` service class with SOQL-optimised queries, bulk-safe DML, and `@AuraEnabled` Apex for LWC integration
- **Trigger Framework** — `AccountTrigger` + `AccountTriggerHandler` implementing the handler pattern: duplicate prevention, auto-defaulting Type field, bulk-safe before/after logic
- **Async Processing** — `UpdateAccountsBatch` (Database.Batchable, 200 records/chunk) scheduled via `ScheduledAccountUpdater` with CRON helpers (daily/hourly/weekly)
- **REST API Layer** — `AccountRestService` (`@RestResource`) exposing full CRUD over `/services/apexrest/accounts/*` with structured JSON responses
- **External Integration** — `ExternalSystemIntegration` for outbound HTTP callouts to external CRM systems with callout mock testing
- **Security & Performance** — `SecurityUtility` (FLS/CRUD enforcement), `QueryOptimizationUtility`, `GovernorLimitMonitor` using the Limits API

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── AccountManager.cls              # Core service — SOQL, DML, @AuraEnabled
│   ├── AccountTriggerHandler.cls       # Trigger handler — duplicate check, defaults
│   ├── UpdateAccountsBatch.cls         # Batch — bulk account updates (200/chunk)
│   ├── ScheduledAccountUpdater.cls     # Scheduler — CRON-driven batch execution
│   ├── AccountRestService.cls          # REST API — GET/POST/PATCH/DELETE
│   ├── ExternalSystemIntegration.cls   # HTTP callouts — external CRM sync
│   ├── SecurityUtility.cls             # FLS/CRUD enforcement utility
│   ├── QueryOptimizationUtility.cls    # SOQL index & selectivity helpers
│   └── GovernorLimitMonitor.cls        # Limits.* monitoring
├── triggers/
│   └── AccountTrigger.trigger          # Account trigger (before/after insert/update/delete)
└── lwc/
    └── accountList/
        ├── accountList.html            # UI — datatable, modals, pagination
        └── accountList.js              # Controller — wire, search, filter, pagination
```

## REST API Endpoints

Base URL: `/services/apexrest/accounts/`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/accounts/` | List all accounts (Name, Industry, Type, Revenue) |
| `GET` | `/accounts/{id}` | Retrieve a single account by Salesforce ID |
| `POST` | `/accounts/` | Create account — body: `{name, industry, type}` |
| `PATCH` | `/accounts/{id}` | Update revenue, phone, or website |
| `DELETE` | `/accounts/{id}` | Delete account by ID |

All endpoints return a structured `ResponseWrapper` JSON: `{success, message, data, statusCode}`.

## Test Coverage

| Class | Coverage |
|-------|----------|
| ExternalSystemIntegration | 99% |
| AccountTriggerHandler | 97% |
| UpdateAccountsBatch | 95% |
| ScheduledAccountUpdater | 93% |
| SecurityUtility | 92% |
| GovernorLimitMonitor | 90% |
| AccountManager | 88% |
| AccountRestService | 84% |

**51 tests · 100% pass rate · all classes exceed the 75% minimum**

## Key Technical Patterns

- **Trigger Handler Pattern** — logic separated from trigger file, single handler class per object
- **Bulk-safe Apex** — all SOQL and DML outside loops, collections used throughout
- **FLS/CRUD Checks** — `Schema.SObjectField.isAccessible()` / `isUpdateable()` enforced before every query and DML
- **with sharing** — all Apex classes enforce org-level sharing rules
- **HttpCalloutMock** — `Test.setMock()` pattern for all outbound callout tests
- **Structured REST Responses** — consistent `ResponseWrapper` across all endpoints

## Deployment

```bash
# Authenticate
sf auth web login --set-default

# Deploy all source
sf project deploy start --source-dir force-app/main/default

# Run all tests
sf apex test run --code-coverage --result-format human

# Run specific class
sf apex test run --class-names AccountRestServiceTest --code-coverage
```

## Tech Stack

`Apex` · `SOQL` · `LWC` · `SFDX` · `Salesforce REST API` · `HTTP Callouts` · `Database.Batchable` · `Schedulable` · `@RestResource` · `HttpCalloutMock` · `Git` · `Salesforce CLI`
