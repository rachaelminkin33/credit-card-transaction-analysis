# Credit Card Transaction & Fraud Analysis

## Overview

An end-to-end SQL analysis of 500,000 credit card transactions using PostgreSQL to examine transaction behavior, card usage, customer characteristics, and observed fraud patterns.

The project combines transaction-level, card-level, and customer-level data to identify patterns in fraud risk and spending behavior. SQL analysis views were created to support downstream business intelligence visualization.

## Business Objective

The goal of this analysis is to answer questions such as:

- Which payment methods have the highest observed fraud rates?
- Does observed fraud vary by card type?
- How does observed fraud rate differ across customer FICO groups?
- How does transaction size vary across income groups?
- Which card types account for the most spending?
- How do customer income and credit score relate to transaction behavior?

## Dataset

The analysis uses a 500,000-transaction working sample from the IBM Credit Card Transactions dataset.

The underlying dataset contains relational information across:

- **Transactions** — transaction activity, amounts, payment methods, and fraud indicators
- **Cards** — card type, brand, credit limit, and other card attributes
- **Users** — customer income, FICO score, and other customer-level attributes

The raw transaction data is not included in this repository due to file size and data sensitivity considerations.

## Data Model

The analysis connects the primary tables through customer and card identifiers:

```text
Users
  │
  │ user_id
  ↓
Transactions
  │
  │ user_id + card_index
  ↕
Cards
```

## SQL Analysis

The project uses PostgreSQL to perform:

- Data validation and completeness checks
- Table joins
- Common Table Expressions (CTEs)
- Conditional aggregation
- `CASE` statements for customer segmentation
- Transaction and spending aggregation
- Fraud-rate calculations
- Customer-level analysis
- Reusable SQL views for business intelligence reporting

The complete analysis script is available in [`sql/credit_card_analysis.sql`](sql/credit_card_analysis.sql).

## Key Findings

### 1. Online transactions showed the highest observed fraud rate

Online transactions had an observed fraud rate of **0.368%**, compared with **0.071%** for chip transactions and **0.042%** for swipe transactions.

This represents an approximately **8.8× higher observed fraud rate for online transactions compared with swipe transactions** in the analyzed sample.

### 2. Prepaid debit had the highest observed fraud rate by card type

Observed fraud rates varied by card type:

| Card Type | Observed Fraud Rate |
|---|---:|
| Debit (Prepaid) | 0.144% |
| Debit | 0.093% |
| Credit | 0.080% |

### 3. Observed fraud rate was lowest among customers with exceptional FICO scores

The Exceptional FICO group (800+) had an observed fraud rate of **0.040%**, compared with **0.116%** for the Good (670–739) group.

The observed rate for the Exceptional group was approximately **65% lower** than the Good group.

### 4. Higher-income customers had larger average transaction sizes

Average transaction size increased substantially across the higher income groups:

| Income Group | Average Transaction |
|---|---:|
| Under $30K | $42.28 |
| $30K–$49K | $40.63 |
| $50K–$74K | $53.07 |
| $75K–$99K | $83.90 |
| $100K+ | $103.90 |

Customers in the $100K+ income group had an average transaction approximately **2.6× larger** than the $30K–$49K group.

### 5. Debit transactions represented the largest share of total spending

Debit transactions accounted for approximately **$16.4M** in spending across the analyzed sample, compared with approximately **$7.6M** for credit and **$0.8M** for prepaid debit.

## Business Implications

The analysis suggests several areas that could warrant further investigation:

- Online transactions may warrant additional fraud monitoring because of their substantially higher observed fraud rate.
- Card type and customer characteristics could potentially be incorporated into fraud-risk segmentation.
- Spending behavior varies considerably across income groups, which may be useful for customer segmentation and transaction profiling.
- Further analysis could examine interactions between payment method, card type, customer characteristics, merchant category, and transaction geography.

These findings describe **observed patterns in the analyzed sample** and should not be interpreted as causal relationships or predictive fraud models.

## Limitations

Several limitations should be considered when interpreting the results:

- The analysis uses a **500,000-transaction working sample** rather than the full transaction dataset.
- Customer representation across income and FICO groups is uneven.
- Some customer segments contain substantially more observations than others.
- Fraud rates represent observed historical patterns in the sample rather than predictions of future fraud.
- The analysis identifies associations and patterns; it does not establish causation.
- Additional statistical modeling would be required to determine whether observed differences remain significant after controlling for other variables.

## Tools

**PostgreSQL | SQL | Tableau Public**

## Project Structure

```text
credit-card-transaction-analysis/
│
├── README.md
│
├── sql/
│   └── credit_card_analysis.sql
│
└── data/
    └── README.md
```

## Next Steps

Potential extensions to this analysis include:

- Building an interactive BI dashboard
- Analyzing fraud trends over time
- Investigating merchant categories associated with fraud
- Examining geographic fraud patterns
- Developing a predictive fraud-risk model
- Expanding the analysis to the full transaction dataset
