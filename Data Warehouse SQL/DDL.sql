CREATE DATABASE BANKING_ETL;
GO
CREATE schema banking;
GO


IF OBJECT_ID('banking.SupportCalls', 'U') IS NOT NULL DROP TABLE banking.SupportCalls;
IF OBJECT_ID('banking.Cards',        'U') IS NOT NULL DROP TABLE banking.Cards;
IF OBJECT_ID('banking.Loans',        'U') IS NOT NULL DROP TABLE banking.Loans;
IF OBJECT_ID('banking.Transactions', 'U') IS NOT NULL DROP TABLE banking.Transactions;
IF OBJECT_ID('banking.Accounts',     'U') IS NOT NULL DROP TABLE banking.Accounts;

GO


/* ────────────────────────────────────────────────────────────
   2.  CUSTOMERS
       Source  : customers.json
       Rows    : 5 000
       Notes   : JoinDate stored as Unix-ms in source →
                 converted to DATE during ETL before load
   ──────────────────────────────────────────────────────────── */

IF OBJECT_ID('banking.Customers',    'U') IS NOT NULL DROP TABLE banking.Customers;
GO
CREATE TABLE banking.Customers (
    CustomerID   INT            NOT NULL,   -- PK, range 1-5000
    FirstName    NVARCHAR(50)   NOT NULL,   -- max observed 11 chars, padded for safety
    LastName     NVARCHAR(50)   NOT NULL,
    Phone        NVARCHAR(30)   NOT NULL,   -- mixed formats, max 22 chars
    Email        NVARCHAR(100)  NOT NULL,   -- max observed 38 chars
    Address      NVARCHAR(200)  NOT NULL,   -- max observed 63 chars
    JoinDate     DATE           NOT NULL,   -- converted from Unix-ms during ETL

    CONSTRAINT PK_Customers PRIMARY KEY CLUSTERED (CustomerID),

);
GO


/* ────────────────────────────────────────────────────────────
   3.  ACCOUNTS
       Source  : Accounts sheet
       Rows    : 5 000
   ──────────────────────────────────────────────────────────── */
CREATE TABLE banking.Accounts (
    AccountID    INT             NOT NULL,   -- PK, range 1-5000
    CustomerID   INT             NOT NULL,   -- FK → Customers
    AccountType  NVARCHAR(10)    NOT NULL,   -- 'Savings' | 'Checking' | 'Business'
    Balance      DECIMAL(12, 2)  NOT NULL,   -- max observed 99 968
    CreatedDate  DATE            NOT NULL,

    CONSTRAINT PK_Accounts PRIMARY KEY CLUSTERED (AccountID),
    CONSTRAINT CK_Accounts_AccountType
        CHECK (AccountType IN ('Savings', 'Checking', 'Business')),
    CONSTRAINT CK_Accounts_Balance
        CHECK (Balance >= 0)
);
GO


/* ────────────────────────────────────────────────────────────
   4.  TRANSACTIONS
       Source  : Transactions sheet
       Rows    : 20 000
   ──────────────────────────────────────────────────────────── */
CREATE TABLE banking.Transactions (
    TransactionID    INT             NOT NULL,   -- PK, range 1-20000
    AccountID        INT             NOT NULL,   -- FK → Accounts
    TransactionType  NVARCHAR(15)    NOT NULL,   -- 'Deposit'|'Withdrawal'|'Transfer'|'Payment'
    Amount           DECIMAL(10, 2)  NOT NULL,   -- max observed 9 999.89
    TransactionDate  DATE            NOT NULL,

    CONSTRAINT PK_Transactions PRIMARY KEY CLUSTERED (TransactionID),
    CONSTRAINT CK_Transactions_Type
        CHECK (TransactionType IN ('Deposit', 'Withdrawal', 'Transfer', 'Payment')),
    CONSTRAINT CK_Transactions_Amount
        CHECK (Amount > 0)
);
GO


/* ────────────────────────────────────────────────────────────
   5.  LOANS
       Source  : Loans sheet
       Rows    : 2 500
   ──────────────────────────────────────────────────────────── */
CREATE TABLE banking.Loans (
    LoanID         INT             NOT NULL,   -- PK, range 1-2500
    CustomerID     INT             NOT NULL,   -- FK → Customers
    LoanType       NVARCHAR(15)    NOT NULL,   -- 'Car'|'Personal'|'Home'|'Education'
    LoanAmount     DECIMAL(12, 2)  NOT NULL,   -- max observed 499 756
    InterestRate   DECIMAL(5, 2)   NOT NULL,   -- range 2.50 - 12.50
    LoanStartDate  DATE            NOT NULL,
    LoanEndDate    DATE            NOT NULL,

    CONSTRAINT PK_Loans PRIMARY KEY CLUSTERED (LoanID),
    CONSTRAINT CK_Loans_Type
        CHECK (LoanType IN ('Car', 'Personal', 'Home', 'Education')),
    CONSTRAINT CK_Loans_Amount
        CHECK (LoanAmount > 0),
    CONSTRAINT CK_Loans_InterestRate
        CHECK (InterestRate > 0),
    CONSTRAINT CK_Loans_Dates
        CHECK (LoanEndDate > LoanStartDate)
);
GO


/* ────────────────────────────────────────────────────────────
   6.  CARDS
       Source  : Cards sheet
       Rows    : 4 000
       Notes   : CardNumber stored as BIGINT — max observed
                 value (~4.9 x 10^18) exceeds INT range
   ──────────────────────────────────────────────────────────── */
CREATE TABLE banking.Cards (
    CardID          INT           NOT NULL,   -- PK, range 1-4000
    CustomerID      INT           NOT NULL,   -- FK → Customers
    CardType        NVARCHAR(10)  NOT NULL,   -- 'Debit' | 'Credit' | 'Prepaid'
    CardNumber      BIGINT        NOT NULL,   -- 16-digit PAN
    IssuedDate      DATE          NOT NULL,
    ExpirationDate  DATE          NOT NULL,

    CONSTRAINT PK_Cards PRIMARY KEY CLUSTERED (CardID),
    CONSTRAINT UQ_Cards_CardNumber UNIQUE (CardNumber),
    CONSTRAINT CK_Cards_Type
        CHECK (CardType IN ('Debit', 'Credit', 'Prepaid')),
    CONSTRAINT CK_Cards_Dates
        CHECK (ExpirationDate > IssuedDate)
);
GO


/* ────────────────────────────────────────────────────────────
   7.  SUPPORTCALLS
       Source  : SupportCalls sheet
       Rows    : 3 000
   ──────────────────────────────────────────────────────────── */
CREATE TABLE banking.SupportCalls (
    CallID      INT           NOT NULL,   -- PK, range 1-3000
    CustomerID  INT           NOT NULL,   -- FK → Customers
    CallDate    DATE          NOT NULL,
    IssueType   NVARCHAR(25)  NOT NULL,   -- max observed 19 chars
    Resolved    CHAR(3)       NOT NULL,   -- 'Yes' | 'No'

    CONSTRAINT PK_SupportCalls PRIMARY KEY CLUSTERED (CallID),
    CONSTRAINT CK_SupportCalls_IssueType
        CHECK (IssueType IN ('Account Access', 'Transaction Dispute',
                             'Loan Query', 'Card Issue')),
    CONSTRAINT CK_SupportCalls_Resolved
        CHECK (Resolved IN ('Yes', 'No'))
);
GO