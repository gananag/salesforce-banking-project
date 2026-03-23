# Salesforce AccountManager Test Execution Guide

## Test Overview
This document provides instructions for running tests for the AccountManager Apex class and viewing test results.

### Test Class: AccountManagerTest
- **Total Test Methods**: 18
- **Expected Code Coverage**: 75%+ 
- **Test Data Setup**: Uses @testSetup to create 4 test accounts with different industries

---

## Method 1: Run Tests via Salesforce CLI (Recommended)

### Command 1: Run All Local Tests
```bash
sf apex run test --test-level RunLocalTests --wait 20 --code-coverage
```

**What this does:**
- Runs all test classes in your org
- Waits up to 20 minutes for completion
- Generates code coverage report
- Executes AccountManagerTest with all 18 test methods

### Command 2: Run Tests with Detailed Output
```bash
sf apex run test --test-level RunLocalTests --code-coverage --result-format human
```

**What this does:**
- Runs tests with human-readable output
- Shows test results in detail
- Displays code coverage percentages

### Command 3: Run Tests with JSON Output (For CI/CD)
```bash
sf apex run test --test-level RunLocalTests --code-coverage --result-format json
```

**What this does:**
- Outputs results in JSON format
- Suitable for integration with CI/CD pipelines
- Easier to parse programmatically

### Command 4: Run Specific Test Class Only
```bash
sf apex run test --class-names AccountManagerTest --code-coverage
```

**What this does:**
- Runs only AccountManagerTest
- Faster execution (doesn't run other org tests)
- More focused testing

---

## Method 2: Run Tests via Salesforce Web UI

### Step-by-Step Instructions:

1. **Open Your Salesforce Org**
   - Log in to your org: https://gananag.syannaneti.brave-panda-ti0u6b.com

2. **Navigate to Test Execution**
   - Go to **Setup** → **Apex Test Execution** (Search in Quick Find)
   - Or go to **Developer Console** → **Test** → **New Run**

3. **Select Test Classes**
   - Check the box for `AccountManagerTest`
   - Click **Run**

4. **View Test Results**
   - Wait for tests to complete
   - View results in the Test Result panel
   - Check for:
     - ✅ Passed tests (green)
     - ❌ Failed tests (red)
     - Code coverage percentage

5. **View Code Coverage**
   - In Developer Console: **Test** → **Code Coverage**
   - Shows coverage for AccountManager class
   - Target: 75%+

---

## Test Methods Overview

### getAccountsByIndustry() Tests (5 tests)

| Test Method | Purpose | Expected Result |
|---|---|---|
| `testGetAccountsByIndustrySuccess` | Valid industry parameter | Returns 1 Technology account |
| `testGetAccountsByIndustryBlankInput` | Blank industry string | Returns empty list |
| `testGetAccountsByIndustryNullInput` | Null industry parameter | Returns empty list |
| `testGetAccountsByIndustryNoResults` | Non-existent industry | Returns empty list |
| `testGetAccountsByIndustryFieldSelection` | Verify all fields returned | All fields populated |

### createAccount() Tests (6 tests)

| Test Method | Purpose | Expected Result |
|---|---|---|
| `testCreateAccountSuccess` | Valid parameters | Account created with ID |
| `testCreateAccountBlankName` | Blank account name | Throws AuraHandledException |
| `testCreateAccountBlankIndustry` | Blank industry | Throws AuraHandledException |
| `testCreateAccountNullName` | Null account name | Throws AuraHandledException |
| `testCreateAccountNullIndustry` | Null industry | Throws AuraHandledException |

### updateAnnualRevenue() Tests (6 tests)

| Test Method | Purpose | Expected Result |
|---|---|---|
| `testUpdateAnnualRevenueSuccess` | Valid parameters | Account revenue updated |
| `testUpdateAnnualRevenueNullAccountId` | Null account ID | Throws AuraHandledException |
| `testUpdateAnnualRevenueNullRevenue` | Null revenue value | Throws AuraHandledException |
| `testUpdateAnnualRevenueInvalidAccountId` | Invalid account ID | Throws AuraHandledException |
| `testUpdateMultipleAccounts` | Update 2 accounts | Both accounts updated |

### Bulk & Coverage Tests (1 test)

| Test Method | Purpose | Expected Result |
|---|---|---|
| `testGetAccountsByIndustryLimit` | LIMIT 100 boundary test | Returns max 100 accounts |
| `testCRUDPermissionChecks` | CRUD permission checks | Validates permission logic |

---

## Quick Test Execution Steps

### For Windows PowerShell (Your Environment):

```powershell
# Step 1: Navigate to project directory
cd "c:\Users\ganan\OneDrive\Documents\salesforce-pd2-project"

# Step 2: Run tests (choose one):

# Option A: Quick test run
sf apex run test --class-names AccountManagerTest --code-coverage

# Option B: Full test run with all local tests
sf apex run test --test-level RunLocalTests --code-coverage

# Option C: Detailed output
sf apex run test --test-level RunLocalTests --code-coverage --result-format human

# Step 3: Check deployment status if deployed as part of deploy
sf project deploy report
```

---

## Expected Test Results

### All Tests Should Pass ✅
- 18/18 tests passing
- 0 failures
- 0 errors

### Code Coverage Expected: 75%+
```
AccountManager.cls Coverage:
- getAccountsByIndustry(): 100% (all paths covered)
- createAccount(): 100% (success + error paths)
- updateAnnualRevenue(): 100% (success + error paths)

Overall Coverage: 95%+
```

---

## Interpreting Test Output

### Success Example:
```
Test Results
============
Tests run:    18
Passed:       18
Failed:       0
Errors:       0

Code Coverage:
AccountManager: 95%
```

### Failure Example (if any test fails):
```
Failed Tests:
- testCreateAccountBlankName: Expected exception not thrown
- Line 89: System.assert(false, 'Should throw AuraHandledException')
```

### How to Debug Failed Tests:
1. Click on the failed test name in the UI
2. Check the "Error Message" column
3. Review the line number mentioned
4. Check the test method in AccountManagerTest.cls
5. Verify test data setup in @testSetup method

---

## Checking Code Coverage in Web UI

1. Open **Developer Console** (Ctrl+Alt+L or Setup → Developer Console)
2. Click **Test** → **Code Coverage**
3. Look for "AccountManager" class
4. Coverage % should be ≥ 75%
5. Green checkmark appears when coverage is sufficient

---

## CI/CD Integration (Optional)

If you want to automate test runs in a CI/CD pipeline:

```bash
# Run tests and save results to file
sf apex run test --test-level RunLocalTests --code-coverage --result-format json > test-results.json

# Check if tests passed (exit code 0 = success, non-zero = failure)
echo $LASTEXITCODE
```

---

## Troubleshooting

### Issue: Tests Not Running
**Solution**: 
- Verify AccountManagerTest.cls is deployed
- Check: `sf project deploy start --source-dir force-app/main/default/classes`

### Issue: CRUD Permission Errors
**Solution**:
- Your user should have Create/Read/Update Account permissions
- Check user profile: Setup → Users → Select user → Check Account permissions

### Issue: Test Setup Data Not Created
**Solution**:
- The @testSetup method runs once before all tests
- If setup fails, all tests fail
- Check for DML exceptions in @testSetup

### Issue: Code Coverage Below 75%
**Solution**:
- All 18 test methods are designed to achieve 95%+ coverage
- Make sure all test methods execute
- Run: `sf apex run test --class-names AccountManagerTest --code-coverage`

---

## Next Steps After Tests Pass

1. ✅ Verify code coverage ≥ 75%
2. ✅ Ensure all 18 tests pass
3. ✅ Review any warnings or logs
4. ✅ Deploy to production org (if ready)

For deployment to production:
```bash
sf project deploy start --target-org prod --test-level RunLocalTests
```

---

## Support & Resources

- [Salesforce Apex Testing Documentation](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing.htm)
- [Test Best Practices](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_testing_best_practices.htm)
- [Salesforce CLI Commands](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)