/* ========================================================================
   1. DIMENSION: CUSTOMERS
   Maps to: banking_analytics.CustomerMetrics
   Grain: 1 row per Customer
   ======================================================================== */
CREATE VIEW banking_analytics.dim_customers AS
SELECT
    CustomerID,
    FirstName,
    LastName,
    total_balance   AS TotalBalance,
    total_transactions AS TotalTransactions,
    total_amount    AS TotalTransactionAmount,
    avg_txn_amount  AS AverageTransactionAmount
FROM banking_analytics.CustomerMetrics;
GO

/* ========================================================================
   2. DIMENSION: ACCOUNTS
   Maps to: banking_analytics.AccountTransactionSummary
   Grain: 1 row per Account
   Note: AccountTransactionSummary already contains both Valid & Suspicious accounts.
   ======================================================================== */
CREATE VIEW banking_analytics.dim_accounts AS
SELECT
    AccountID,
    CustomerID,
    AccountType,
    Balance,
    balance_status   AS BalanceStatus,
    total_deposits   AS TotalDeposits,
    total_withdrawals AS TotalWithdrawals,
    total_transfers  AS TotalTransfers,
    total_payments   AS TotalPayments,
    total_outflow    AS TotalOutflow,
    net_txn_activity AS NetTransactionActivity,
    outflow_vs_balance AS OutflowVsBalance
FROM banking_analytics.AccountTransactionSummary;
GO

/* ========================================================================
   3. FACT: TRANSACTIONS
   Maps to: banking_analytics.MonthlyActivity
   Grain: Customer-Month (aggregated transactional activity per month)
   Note: Raw transaction tables aren't provided, so this uses the most granular
         time-based activity table available.
   ======================================================================== */
CREATE VIEW banking_analytics.fact_transactions AS
SELECT
    CustomerID,
    year_month        AS PeriodKey,
    monthly_txn_count AS TransactionCount,
    monthly_txn_amount AS TransactionAmount
FROM banking_analytics.MonthlyActivity;
GO