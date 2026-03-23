<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Salesforce Platform Developer 2 Project Guidelines

This is a Salesforce platform development project focused on preparing for the Salesforce Certified Platform Developer II exam.

## Project Structure
- **force-app/main/default/classes**: Apex classes for business logic
- **force-app/main/default/lwc**: Lightning Web Components for UI
- **sfdx-project.json**: Salesforce DX configuration

## Code Standards
1. Follow Salesforce naming conventions (PascalCase for classes, camelCase for variables)
2. Always include JSDoc comments for public methods
3. Use descriptive variable names
4. Implement proper error handling in Apex and LWC
5. Write SOQL queries efficiently to avoid governor limits

## Key Concepts to Master
- **Apex**: SOQL/SOSL queries, DML operations, triggers, batch classes
- **Lightning Web Components**: Wire adapters, decorators, lifecycle hooks
- **Governor Limits**: Always be aware of Salesforce platform limitations
- **Security**: Implement CRUD/FLS checks, input validation

## Deployment
Use Salesforce DX CLI commands:
```bash
sf auth web login
sf project deploy start
sf project retrieve start
```

## Testing
- Write comprehensive Apex test classes
- Aim for 75%+ code coverage
- Use @isTest annotation for test classes
