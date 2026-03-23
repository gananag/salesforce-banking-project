# Salesforce Platform Developer 2 Project

A comprehensive project setup for preparing for the **Salesforce Certified Platform Developer II** exam.

## Overview

This project provides a foundational structure for developing Salesforce solutions using modern tools and best practices. It includes sample Apex classes, Lightning Web Components, and configuration files aligned with Salesforce DX.

## Project Structure

```
salesforce-pd2-project/
├── force-app/
│   └── main/
│       └── default/
│           ├── classes/           # Apex classes
│           │   ├── AccountManager.cls
│           │   └── AccountManager.cls-meta.xml
│           └── lwc/               # Lightning Web Components
│               └── accountList/
│                   ├── accountList.js
│                   ├── accountList.html
│                   └── accountList.js-meta.xml
├── sfdx-project.json              # Salesforce DX configuration
├── .forceignore                   # Files to ignore during deployment
├── .gitignore                     # Git ignore rules
└── package.json                   # Node.js project file
```

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli) installed
- A Salesforce Developer Edition org or scratch org
- [Visual Studio Code](https://code.visualstudio.com/) with Salesforce extensions
- Node.js and npm

## Getting Started

### 1. Install Salesforce CLI

Download and install the latest version from [Salesforce CLI](https://developer.salesforce.com/tools/sfdxcli).

### 2. Authenticate with Salesforce

```bash
sf auth web login --set-default
```

### 3. Create a Scratch Org (Optional)

```bash
sf org create scratch --definition-file config/project-scratch-def.json --set-default
```

### 4. Deploy Source to Org

```bash
sf project deploy start
```

## Key Components

### Apex Class: AccountManager
- `getAccountsByIndustry()`: Retrieves accounts filtered by industry
- `createAccount()`: Creates a new account record
- `updateAnnualRevenue()`: Updates account revenue

### Lightning Web Component: accountList
- Displays accounts by selected industry
- Uses `@wire` decorator for real-time data loading
- Implements datatable with row actions
- Error handling with lightning-alert

## Important Concepts for PD2 Exam

### Apex Fundamentals
- SOQL and SOSL queries
- DML operations (insert, update, delete, upsert)
- Governor limits and best practices
- Exception handling
- Asynchronous processing (batch, scheduled, queueable)

### Lightning Web Components
- Component lifecycle hooks
- Wire adapters and imperative Apex calls
- Event handling and communication
- Decorators (@track, @wire, @api)
- Styling with SLDS

### Advanced Topics
- Triggers and trigger design patterns
- Batch processing and scheduled jobs
- REST and SOAP APIs
- Platform security (CRUD, FLS, Sharing)
- Internationalization and localization

## Resources

- [Salesforce Apex Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/)
- [Lightning Web Components Documentation](https://developer.salesforce.com/docs/component-library/documentation/en/lwc)
- [Salesforce DX Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/)
- [PD2 Exam Guide](https://developer.salesforce.com/certification/platform_developer_2)

## Common Commands

```bash
# List all orgs
sf org list

# Run SOQL query
sf data query --query "SELECT Id, Name FROM Account" --target-org <org-alias>

# Retrieve metadata
sf project retrieve start --target-org <org-alias>

# Execute anonymous Apex
sf apex execute --file script.apex --target-org <org-alias>

# Run tests
sf apex test run --target-org <org-alias>
```

## Development Workflow

1. **Create/Modify Code**: Update Apex classes and LWC components locally
2. **Push Changes**: Use `sf project deploy start` to push to your org
3. **Test**: Run tests and verify functionality
4. **Retrieve**: Use `sf project retrieve start` to pull changes from the org
5. **Commit**: Commit changes to git repository

## Tips for Success

- ✅ Always check for SOQL query limits and use pagination where needed
- ✅ Implement proper error handling in all Apex code
- ✅ Use meaningful variable and method names
- ✅ Write comprehensive test coverage (aim for 75%+)
- ✅ Leverage Lightning Web Components over Aura
- ✅ Follow Salesforce naming conventions
- ✅ Keep methods focused and single-purpose
- ✅ Use platform events for asynchronous communication

## License

ISC

## Support

For questions about Salesforce development, refer to the [Salesforce Developer Community](https://developer.salesforce.com/forums).
