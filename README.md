# Banking-ETL-Pipeline-Data-Processing
Objective Design and implement a robust ETL pipeline that processes raw banking transaction data and produces accurate, consistent, and analysis-ready datasets.


# Banking Analytics – Task 1: Data Understanding & Risk Identification

---

## 1. Dataset Overview

### A. `customers.json`
A flat JSON array of **5,000 customer records** — the master identity table for all persons in the system.

| Field | Type | Description |
|---|---|---|
| `CustomerID` | integer | Primary key (1–5000, sequential, unique) |
| `FirstName` / `LastName` | string | Customer name |
| `Phone` | string | Contact number (mixed formats) |
| `Email` | string | Contact email |
| `Address` | string | Full postal address |
| `JoinDate` | integer | Unix millisecond timestamp (e.g., `1575763200000` → 2019-12-08) |

**Key facts:** No nulls. No duplicate `CustomerID`. Covers join dates from **May 2015 to May 2025**. Not all customers have accounts — 1,829 customers exist in this file but have no matching account in the Excel dataset (potential inactive/prospect records).

---

### B. `Banking_Analytics_Dataset.xlsx` — 5 Sheets

#### Sheet 1: `Accounts` (5,000 rows)
The core account ledger. Each row is one bank account.

| Field | Type | Description |
|---|---|---|
| `AccountID` | integer | Primary key |
| `CustomerID` | integer | FK → `customers.json` |
| `AccountType` | string | `Savings`, `Checking`, or `Business` |
| `Balance` | integer | Current balance in local currency |
| `CreatedDate` | date | Account opening date |

**Key facts:** No nulls or duplicates. Balances range from **147 to 99,968**. All 3,171 unique customers who appear here exist in `customers.json`. **1,342 customers hold more than one account** (multi-account relationship).

---

#### Sheet 2: `Transactions` (20,000 rows)
A log of all financial movements against accounts.

| Field | Type | Description |
|---|---|---|
| `TransactionID` | integer | Primary key |
| `AccountID` | integer | FK → `Accounts` |
| `TransactionType` | string | `Deposit`, `Withdrawal`, `Transfer`, or `Payment` |
| `Amount` | float | Transaction value |
| `TransactionDate` | date | Date of transaction |

**Key facts:** No nulls or duplicates. Amounts range from **10.18 to 9,999.89**. Date range: **May 2022 – May 2025**. All `AccountID` values resolve correctly to the Accounts sheet.

---

#### Sheet 3: `Loans` (2,500 rows)
Records of all loan products issued to customers.

| Field | Type | Description |
|---|---|---|
| `LoanID` | integer | Primary key |
| `CustomerID` | integer | FK → `customers.json` |
| `LoanType` | string | `Car`, `Personal`, `Home`, or `Education` |
| `LoanAmount` | integer | Principal amount |
| `InterestRate` | float | Annual rate (%) |
| `LoanStartDate` | date | Disbursement date |
| `LoanEndDate` | date | Maturity date |

**Key facts:** Interest rates range from **2.5% to 12.5%**. Loan amounts are all positive. No invalid date ordering (end always after start). **472 customers hold multiple loans**. However, **916 loan records (36.6%) reference a CustomerID not present in the Accounts sheet** — these customers took loans without a linked deposit account, or the accounts data is incomplete.

---

#### Sheet 4: `Cards` (4,000 rows)
Issued payment cards linked to customers.

| Field | Type | Description |
|---|---|---|
| `CardID` | integer | Primary key |
| `CustomerID` | integer | FK → `customers.json` |
| `CardType` | string | `Debit`, `Credit`, or `Prepaid` |
| `CardNumber` | integer | 16-digit card number |
| `IssuedDate` | date | Card issue date |
| `ExpirationDate` | date | Card expiry date |

**Key facts:** No duplicate card numbers. No cards with expiry before issue date. However, **1,468 card records (36.7%) reference a CustomerID with no matching account** — same pattern as Loans, suggesting a broader referential integrity gap.

---

#### Sheet 5: `SupportCalls` (3,000 rows)
Customer service interaction log.

| Field | Type | Description |
|---|---|---|
| `CallID` | integer | Primary key |
| `CustomerID` | integer | FK → `customers.json` |
| `CallDate` | date | Date of call |
| `IssueType` | string | `Account Access`, `Transaction Dispute`, `Loan Query`, or `Card Issue` |
| `Resolved` | string | `Yes` or `No` |

**Key facts:** **1,521 calls (50.7%) remain unresolved** — a significant operational signal. **1,090 call records (36.3%) reference a CustomerID not present in the Accounts sheet**, consistent with the loan/card pattern above.

---

## 2. Identified Data Issues & Risks

| # | Issue | Affected Dataset(s) | Severity | Notes |
|---|---|---|---|---|
| 1 | **Orphaned foreign keys** | Loans, Cards, SupportCalls | 🔴 High | ~36% of records in each table reference CustomerIDs with no linked account. Could indicate missing account data, closed accounts, or customers who never opened a deposit account. Must be resolved before any join-based analysis. |
| 2 | **Inactive customers** | customers.json ↔ Accounts | 🟡 Medium | 1,829 customers in the JSON file have no account. They may be prospects, former customers, or data entry gaps. |
| 3 | **`JoinDate` stored as Unix milliseconds** | customers.json | 🟡 Medium | Raw value is an integer (e.g., `1575763200000`) — not human-readable. Must be converted to a date during ETL. |
| 4 | **Duplicate emails** | customers.json | 🟡 Medium | 11 email addresses appear more than once. Could indicate shared family emails or duplicate customer registrations. Needs deduplication review. |
| 5 | **`Balance` never negative** | Accounts | 🟢 Low | No overdrafts exist. This may be realistic but should be confirmed as a business rule, not a data gap. |
| 6 | **Transactions not directly tied to customers** | Transactions | 🟢 Low | Transactions join to Accounts, not Customers — a customer-level spending view requires a two-step join (`Transactions → Accounts → Customers`). |
| 7 | **High unresolved call rate** | SupportCalls | 🟡 Medium | 50.7% of calls are unresolved. This is not a data quality issue per se, but a significant analytical finding that should be surfaced in dashboards. |
| 8 | **Mixed phone number formats** | customers.json | 🟢 Low | Phone numbers use inconsistent formats (e.g., `(107)429-6508`, `+1-936-234-0473x4335`). Normalisation needed before any contact/communications analysis. |

---

## 3. ETL Pipeline Steps

```
RAW DATA
   │
   ├─ customers.json
   └─ Banking_Analytics_Dataset.xlsx (5 sheets)
         │
         ▼
STEP 1: EXTRACT
  - Load customers.json via Python (json / pandas)
  - Load each Excel sheet via pandas (read_excel)

STEP 2: TRANSFORM — customers.json
  - Convert JoinDate from Unix ms → datetime (pd.to_datetime(..., unit="ms"))
  - Standardise phone number format (regex normalisation)
  - Flag / deduplicate 11 duplicate emails (retain one per CustomerID)

STEP 3: TRANSFORM — Accounts
  - Validate AccountType ∈ {Savings, Checking, Business}
  - Confirm Balance ≥ 0; flag any negatives if they appear in future data
  - Parse / validate CreatedDate

STEP 4: TRANSFORM — Transactions
  - Validate TransactionType ∈ {Deposit, Withdrawal, Transfer, Payment}
  - Confirm Amount > 0
  - Verify all AccountIDs exist in cleaned Accounts table
  - Parse TransactionDate

STEP 5: TRANSFORM — Loans
  - Validate LoanType ∈ {Car, Personal, Home, Education}
  - Confirm LoanAmount > 0 and InterestRate within plausible range
  - Confirm LoanEndDate > LoanStartDate
  - Tag the 916 orphaned CustomerIDs as "account-less loan holders"
    (retain for analysis but flag with a boolean column: has_account = False)

STEP 6: TRANSFORM — Cards
  - Validate CardType ∈ {Debit, Credit, Prepaid}
  - Confirm ExpirationDate > IssuedDate
  - Confirm CardNumber uniqueness
  - Tag the 1,468 orphaned CustomerIDs similarly (has_account = False)

STEP 7: TRANSFORM — SupportCalls
  - Validate IssueType and Resolved values
  - Tag 1,090 orphaned CustomerIDs (has_account = False)
  - Derive a boolean: is_resolved = (Resolved == "Yes")

STEP 8: LOAD
  - Load all cleaned tables into target store (e.g., SQLite / PostgreSQL / data warehouse)
  - Enforce FK constraints or create a surrogate "account-less customer" category
  - Create the following derived join views:
      • customer_accounts: customers ⟕ accounts (left join)
      • account_transactions: accounts ⟕ transactions
      • customer_full_view: customers ⟕ accounts ⟕ loans ⟕ cards ⟕ support_calls

STEP 9: VALIDATE
  - Row count checks (source vs. loaded)
  - Null checks on primary keys
  - Range checks on numeric fields (Balance, Amount, InterestRate)
  - Referential integrity audit report
```

---

*Generated as part of Banking Analytics Pipeline — Task 1*