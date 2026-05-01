import { LightningElement, wire } from 'lwc';
import getAccountsByIndustry from '@salesforce/apex/AccountManager.getAccountsByIndustry';
import createAccount from '@salesforce/apex/AccountManager.createAccount';
import updateAnnualRevenue from '@salesforce/apex/AccountManager.updateAnnualRevenue';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class AccountList extends LightningElement {
    selectedIndustry = '';
    accounts = [];
    searchTerm = '';
    error = undefined;
    isLoading = false;

    // Pagination state
    currentPage = 1;
    pageSize = 10;

    // Create form state
    createForm = {
        accountName: '',
        industry: ''
    };
    createError = '';
    isCreating = false;

    // Revenue form state
    revenueForm = {
        accountId: '',
        accountName: '',
        revenue: ''
    };
    revenueError = '';
    isUpdating = false;

    industryOptions = [
        { label: 'Technology', value: 'Technology' },
        { label: 'Finance', value: 'Finance' },
        { label: 'Healthcare', value: 'Healthcare' },
        { label: 'Manufacturing', value: 'Manufacturing' },
        { label: 'Retail', value: 'Retail' }
    ];

    /**
     * Getter to safely extract error message
     * @return {string} Error message or default message
     */
    get errorMessage() {
        return this.error?.body?.message || 'An error occurred while loading accounts';
    }

    /**
     * Wire method to fetch accounts by selected industry
     * @param {Object} error - Error object if query fails
     * @param {Array} data - List of Account records
     */
    @wire(getAccountsByIndustry, { industry: '$selectedIndustry' })
    wiredAccounts({ error, data }) {
        if (data) {
            this.accounts = data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.accounts = [];
            console.error('Error fetching accounts:', error);
        }
    }

    /**
     * Handles industry dropdown change event
     * @param {Event} event - Change event from combobox
     */
    handleIndustryChange(event) {
        this.selectedIndustry = event.detail.value;
    }

    /**
     * Handles search input change event
     * @param {Event} event - Change event from search input
     */
    handleSearchChange(event) {
        this.searchTerm = event.detail.value.trim().toLowerCase();
    }

    /**
     * Getter to filter accounts based on selected industry and search term
     * @return {Array} Filtered array of Account records
     */
    get filteredAccounts() {
        if (!this.accounts || this.accounts.length === 0) {
            return [];
        }

        return this.accounts.filter(account => {
            // Filter by search term (account name)
            if (this.searchTerm) {
                const accountName = account.Name ? account.Name.toLowerCase() : '';
                if (!accountName.includes(this.searchTerm)) {
                    return false;
                }
            }
            return true;
        });
    }

    /**
     * Getter to check if any filters are active
     * @return {boolean} True if industry or search term is set
     */
    get hasActiveFilters() {
        return this.selectedIndustry || this.searchTerm;
    }

    /**
     * Getter to display active filter labels
     * @return {string} Label describing active filters
     */
    get activeFiltersLabel() {
        const filters = [];
        if (this.selectedIndustry) {
            filters.push(`Industry: ${this.selectedIndustry}`);
        }
        if (this.searchTerm) {
            filters.push(`Search: "${this.searchTerm}"`);
        }
        return filters.join(' • ');
    }

    /**
     * Opens the create account modal
     */
    handleOpenCreateModal() {
        this.createForm = { accountName: '', industry: '' };
        this.createError = '';
        this.refs.createModal.show();
    }

    /**
     * Closes the create account modal
     */
    handleCloseCreateModal() {
        this.refs.createModal.hide();
    }

    /**
     * Handles form input changes in create modal
     * @param {Event} event - Change event from form input
     */
    handleCreateFormChange(event) {
        const { name, value } = event.target;
        this.createForm = {
            ...this.createForm,
            [name]: value
        };
        this.createError = ''; // Clear error on input change
    }

    /**
     * Handles create account submission
     */
    handleCreateAccount() {
        // Validate form
        if (!this.createForm.accountName.trim()) {
            this.createError = 'Account name is required.';
            return;
        }
        if (!this.createForm.industry) {
            this.createError = 'Industry is required.';
            return;
        }

        this.isCreating = true;

        createAccount({
            accountName: this.createForm.accountName,
            industry: this.createForm.industry
        })
            .then((result) => {
                // Close modal
                this.handleCloseCreateModal();
                
                // Show success notification
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Account "${result.Name}" created successfully!`,
                        variant: 'success'
                    })
                );

                // Refresh account list if the created industry matches selected industry
                if (this.selectedIndustry === this.createForm.industry) {
                    this.selectedIndustry = ''; // Reset
                    setTimeout(() => {
                        this.selectedIndustry = this.createForm.industry; // Re-trigger wire
                    }, 100);
                }

                // Reset form
                this.createForm = { accountName: '', industry: '' };
            })
            .catch((error) => {
                console.error('Error creating account:', error);
                this.createError = error?.body?.message || 'An error occurred while creating the account.';
            })
            .finally(() => {
                this.isCreating = false;
            });
    }

    columns = [
        { label: 'Account Name', fieldName: 'Name', type: 'text' },
        { label: 'Industry', fieldName: 'Industry', type: 'text' },
        { label: 'Type', fieldName: 'Type', type: 'text' },
        {
            type: 'action',
            typeAttributes: {
                rowActions: [
                    { label: 'View', name: 'view' },
                    { label: 'Edit', name: 'edit' }
                ]
            }
        }
    ];

    /**
     * Handles row action events (View and Edit button clicks)
     * @param {Event} event - Row action event
     */
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;

        if (action.name === 'view') {
            window.open('/' + row.Id, '_blank');
        } else if (action.name === 'edit') {
            this.handleOpenRevenueModal(row);
        }
    }

    /**
     * Opens the revenue update modal with selected account data
     * @param {Object} account - Account record from datatable
     */
    handleOpenRevenueModal(account) {
        this.revenueForm = {
            accountId: account.Id,
            accountName: account.Name,
            revenue: account.AnnualRevenue || ''
        };
        this.revenueError = '';
        this.refs.revenueModal.show();
    }

    /**
     * Closes the revenue update modal
     */
    handleCloseRevenueModal() {
        this.refs.revenueModal.hide();
    }

    /**
     * Handles form input changes in revenue modal
     * @param {Event} event - Change event from form input
     */
    handleRevenueFormChange(event) {
        const { name, value } = event.target;
        this.revenueForm = {
            ...this.revenueForm,
            [name]: value
        };
        this.revenueError = ''; // Clear error on input change
    }

    /**
     * Handles revenue update submission
     */
    handleUpdateRevenue() {
        // Validate form
        if (!this.revenueForm.revenue) {
            this.revenueError = 'Revenue is required.';
            return;
        }

        const revenueValue = parseFloat(this.revenueForm.revenue);
        if (isNaN(revenueValue) || revenueValue < 0) {
            this.revenueError = 'Revenue must be a valid positive number.';
            return;
        }

        this.isUpdating = true;

        updateAnnualRevenue({
            accountId: this.revenueForm.accountId,
            annualRevenue: revenueValue
        })
            .then(() => {
                // Close modal
                this.handleCloseRevenueModal();
                
                // Show success notification
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: `Revenue for "${this.revenueForm.accountName}" updated successfully!`,
                        variant: 'success'
                    })
                );

                // Refresh account list
                if (this.selectedIndustry) {
                    this.selectedIndustry = '';
                    setTimeout(() => {
                        this.selectedIndustry = this.revenueForm.industry || '';
                    }, 100);
                }

                // Reset form
                this.revenueForm = { accountId: '', accountName: '', revenue: '' };
            })
            .catch((error) => {
                console.error('Error updating revenue:', error);
                this.revenueError = error?.body?.message || 'An error occurred while updating revenue.';
            })
            .finally(() => {
                this.isUpdating = false;
            });
    }

    /**
     * Getter to calculate paginated accounts for current page
     * @return {Array} Array of accounts for the current page
     */
    get paginatedAccounts() {
        const startIndex = (this.currentPage - 1) * this.pageSize;
        const endIndex = startIndex + this.pageSize;
        return this.filteredAccounts.slice(startIndex, endIndex);
    }

    /**
     * Getter to calculate total number of pages
     * @return {number} Total pages based on filtered accounts
     */
    get totalPages() {
        return Math.ceil(this.filteredAccounts.length / this.pageSize) || 1;
    }

    /**
     * Getter to check if pagination controls should be displayed
     * @return {boolean} True if more than one page exists
     */
    get hasPagination() {
        return this.totalPages > 1;
    }

    /**
     * Getter to calculate the starting index for display
     * @return {number} 1-based index of first account on current page
     */
    get pageStartIndex() {
        return (this.currentPage - 1) * this.pageSize + 1;
    }

    /**
     * Getter to calculate the ending index for display
     * @return {number} 1-based index of last account on current page
     */
    get pageEndIndex() {
        return Math.min(this.currentPage * this.pageSize, this.filteredAccounts.length);
    }

    /**
     * Getter to determine if Previous button should be disabled
     * @return {boolean} True if on first page
     */
    get isPreviousDisabled() {
        return this.currentPage === 1;
    }

    /**
     * Getter to determine if Next button should be disabled
     * @return {boolean} True if on last page
     */
    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }

    /**
     * Handles previous page button click
     */
    handlePreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
        }
    }

    /**
     * Handles next page button click
     */
    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
        }
    }
}
