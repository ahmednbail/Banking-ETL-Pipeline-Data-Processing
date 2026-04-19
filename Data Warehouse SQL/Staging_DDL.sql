--CREATE DATABASE BANKING_ETL;
--GO
--CREATE schema banking_analytics;
--GO

IF OBJECT_ID('banking_analytics.MonthlyActivity',         'U') IS NOT NULL DROP TABLE banking_analytics.MonthlyActivity;
IF OBJECT_ID('banking_analytics.MonthlySummary',          'U') IS NOT NULL DROP TABLE banking_analytics.MonthlySummary;
IF OBJECT_ID('banking_analytics.SuspiciousAccounts',      'U') IS NOT NULL DROP TABLE banking_analytics.SuspiciousAccounts;
IF OBJECT_ID('banking_analytics.ValidAccounts',           'U') IS NOT NULL DROP TABLE banking_analytics.ValidAccounts;
IF OBJECT_ID('banking_analytics.AccountTransactionSummary','U') IS NOT NULL DROP TABLE banking_analytics.AccountTransactionSummary;
IF OBJECT_ID('banking_analytics.CustomerMetrics',         'U') IS NOT NULL DROP TABLE banking_analytics.CustomerMetrics;
GO



CREATE TABLE banking_analytics.AccountTransactionSummary (
    AccountID          INT             NOT NULL,   -- PK, range 1-5000
    CustomerID         INT             NOT NULL,   -- FK → banking.Customers
    AccountType        NVARCHAR(10)    NOT NULL,   -- Savings | Checking | Business
    Balance            DECIMAL(12, 2)  NOT NULL,   -- stored balance, range 147-99968
    total_deposits     DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_withdrawals  DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_transfers    DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_payments     DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_outflow      DECIMAL(12, 2)  NOT NULL DEFAULT 0,   -- withdrawals + payments
    net_txn_activity   DECIMAL(12, 2)  NOT NULL DEFAULT 0,   -- can be negative
    outflow_vs_balance DECIMAL(12, 2)  NOT NULL DEFAULT 0,   -- can be negative
    balance_status     NVARCHAR(10)    NOT NULL,   -- 'Valid' | 'Suspicious'

    CONSTRAINT PK_AccountTransactionSummary
        PRIMARY KEY CLUSTERED (AccountID),
);
GO



CREATE TABLE banking_analytics.ValidAccounts (
    AccountID          INT             NOT NULL,
    CustomerID         INT             NOT NULL,
    AccountType        NVARCHAR(10)    NOT NULL,
    Balance            DECIMAL(12, 2)  NOT NULL,
    total_deposits     DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_withdrawals  DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_transfers    DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_payments     DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_outflow      DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    net_txn_activity   DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    outflow_vs_balance DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    balance_status     NVARCHAR(10)    NOT NULL DEFAULT 'Valid',

    CONSTRAINT PK_ValidAccounts
        PRIMARY KEY CLUSTERED (AccountID),
);
GO


CREATE TABLE banking_analytics.SuspiciousAccounts (
    AccountID          INT             NOT NULL,
    CustomerID         INT             NOT NULL,
    AccountType        NVARCHAR(10)    NOT NULL,
    Balance            DECIMAL(12, 2)  NOT NULL,
    total_deposits     DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_withdrawals  DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_transfers    DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_payments     DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    total_outflow      DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    net_txn_activity   DECIMAL(12, 2)  NOT NULL DEFAULT 0,
    outflow_vs_balance DECIMAL(12, 2)  NOT NULL,   -- always > 0 in this table
    balance_status     NVARCHAR(10)    NOT NULL DEFAULT 'Suspicious',

    CONSTRAINT PK_SuspiciousAccounts
        PRIMARY KEY CLUSTERED (AccountID),

);
GO



CREATE TABLE banking_analytics.CustomerMetrics (
    CustomerID         INT             NOT NULL,   -- PK, range 1-5000
    FirstName          NVARCHAR(50)    NOT NULL,   -- max observed 11 chars
    LastName           NVARCHAR(50)    NOT NULL,
    total_balance      DECIMAL(12, 2)  NOT NULL DEFAULT 0,   -- max 352,098
    total_transactions INT             NOT NULL DEFAULT 0,   -- max 34
    total_amount       DECIMAL(12, 2)  NOT NULL DEFAULT 0,   -- max 171,818.39
    avg_txn_amount     DECIMAL(10, 4)  NOT NULL DEFAULT 0,   -- 4 d.p. for precision

    CONSTRAINT PK_CustomerMetrics
        PRIMARY KEY CLUSTERED (CustomerID),
);
GO



CREATE TABLE banking_analytics.MonthlyActivity (
    CustomerID          INT             NOT NULL,   -- FK → banking.Customers
    year_month          CHAR(7)         NOT NULL,   -- format: 'YYYY-MM', e.g. '2024-03'
    monthly_txn_count   INT             NOT NULL,   -- range 1-4
    monthly_txn_amount  DECIMAL(12, 2)  NOT NULL,   -- range 10.18-29,476.90

    CONSTRAINT PK_MonthlyActivity
        PRIMARY KEY CLUSTERED (CustomerID, year_month),
);
GO



CREATE TABLE banking_analytics.MonthlySummary (
    year_month          CHAR(7)         NOT NULL,   -- 'YYYY-MM'
    active_customers    INT             NOT NULL,   -- range 191-543
    total_transactions  INT             NOT NULL,   -- range 197-612
    total_amount        DECIMAL(14, 2)  NOT NULL,   -- max ~3,165,783.73

    CONSTRAINT PK_MonthlySummary
        PRIMARY KEY CLUSTERED (year_month),
);
GO





