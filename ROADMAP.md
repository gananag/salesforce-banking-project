# Salesforce PD2 Project - Step-by-Step Roadmap

## Overview
This document provides a detailed step-by-step implementation roadmap for enhancing your Salesforce AccountManager project. Each phase builds on the previous one.

---

## 📊 PHASE 1: Enhanced Account Management UI
**Estimated Time: 2-3 hours | Difficulty: Beginner-Intermediate**

### Step 1.1: ✅ COMPLETED - Add Create Account Modal

**What was done:**
- Added "Create Account" button to accountList component
- Implemented modal form with Account Name and Industry fields
- Integrated with existing `createAccount()` Apex method
- Added form validation and error handling
- Success notification on account creation

**Files Modified:**
- `accountList.html` - Added button and modal UI
- `accountList.js` - Added create account logic

**Key Features:**
- Modal opens/closes properly
- Form validation (required fields)
- Calls Apex method with parameters
- Shows success toast notification
- Auto-refreshes account list if industry matches
- Displays error messages in modal

**Test it:**
1. Deploy code: `sf project deploy start`
2. Open the accountList component
3. Click "Create Account" button
4. Fill in Account Name and select Industry
5. Click "Create" - should see success message
6. New account should appear in list if industry is selected

---

### Step 1.2: Add Edit/Update Revenue Functionality
**Status: NEXT**
**Estimated Time: 1.5 hours**

**What we'll do:**
- Add "Edit" action to datatable row actions
- Create modal for editing annual revenue
- Call `updateAnnualRevenue()` Apex method
- Auto-refresh table after update
- Show success notification

**Implementation Details:**
1. Update `accountList.html`:
   - Add Edit action to datatable row actions
   - Add revenue update modal

2. Update `accountList.js`:
   - Add edit form state (accountId, annualRevenue)
   - Add `handleEditAccount()` method
   - Add `handleUpdateRevenue()` method
   - Update `handleRowAction()` to handle edit action

**Reply: YES when ready for Step 1.2**

---

### Step 1.3: Add Search/Filter Functionality
**Status: PENDING | Estimated Time: 1 hour**

**What we'll do:**
- Add search input field to filter accounts by name
- Implement client-side filtering
- Combine industry filter + search filter

---

### Step 1.4: Add Pagination
**Status: PENDING | Estimated Time: 1 hour**

**What we'll do:**
- Add pagination controls
- Display 10 accounts per page
- Navigate between pages

---

## 🔧 PHASE 2: Advanced Apex Features (PD2 Exam Prep)
**Estimated Time: 3-4 hours | Difficulty: Intermediate-Advanced**

### Step 2.1: Create AccountTrigger with Handler Pattern
**Status: PENDING | Estimated Time: 1.5 hours**

**What we'll build:**
- `AccountTrigger.trigger` - Main trigger file
- `AccountTriggerHandler.cls` - Handler class with business logic
- `AccountTriggerHandlerTest.cls` - Test class

**Key Features:**
- Update LastModifiedDate on account changes
- Prevent duplicate account names
- Auto-populate Type field if blank
- Comprehensive test coverage (10+ tests)

---

### Step 2.2: Create Batch Class for Bulk Updates
**Status: PENDING | Estimated Time: 1 hour**

**What we'll build:**
- `UpdateAccountsBatch.cls` - Batch class to update all accounts
- `UpdateAccountsBatchTest.cls` - Test class

**Key Features:**
- Batch size: 200 records
- Updates Description field with timestamp
- Implements Database.Batchable interface
- Comprehensive error handling

---

### Step 2.3: Create Scheduled Job
**Status: PENDING | Estimated Time: 1 hour**

**What we'll build:**
- `ScheduledAccountUpdater.cls` - Schedulable class
- `ScheduledAccountUpdaterTest.cls` - Test class

**Key Features:**
- Implements Schedulable interface
- Executes batch job on schedule
- Can be scheduled for daily execution

---

## 🌐 PHASE 3: Advanced LWC & Data Display
**Estimated Time: 2-3 hours | Difficulty: Intermediate**

### Step 3.1: Add Related Records Display
**Status: PENDING | Estimated Time: 1.5 hours**

**What we'll do:**
- Display related Contacts in expandable section
- Display related Opportunities
- Use nested components

---

### Step 3.2: Add Charts/Dashboards
**Status: PENDING | Estimated Time: 1.5 hours**

**What we'll do:**
- Create account statistics dashboard
- Show accounts by industry (pie chart)
- Show accounts by type (bar chart)

---

## 🔒 PHASE 4: Security & Performance
**Estimated Time: 2 hours | Difficulty: Intermediate-Advanced**

### Step 4.1: Implement Sharing Rules
**Status: PENDING**

### Step 4.2: Query Optimization
**Status: PENDING**

### Step 4.3: Governor Limit Monitoring
**Status: PENDING**

---

## 🔗 PHASE 5: REST API & Integration
**Estimated Time: 2-3 hours | Difficulty: Advanced**

### Step 5.1: Build REST API Endpoints
**Status: PENDING**

### Step 5.2: Add External System Integration
**Status: PENDING**

---

## 📝 Testing Commands

After each step, run these commands:

```bash
sf project deploy start
sf apex run test --class-names AccountManagerTest --code-coverage
sf apex log tail
sf data query --query "SELECT Id, Name, Industry FROM Account LIMIT 5"
```

---

## 🎯 Recommended Timeline

**Week 1:** Complete Phase 1 (Steps 1.1-1.4)
**Week 2:** Complete Phase 2 (Steps 2.1-2.3)
**Week 3:** Complete Phase 3 (Steps 3.1-3.2)

Each step covers key PD2 exam concepts!