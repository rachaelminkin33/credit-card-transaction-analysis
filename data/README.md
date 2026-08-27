# Data

The analysis uses a 500,000-transaction working sample from the IBM Credit Card Transactions dataset.

The raw transaction data is not included in this repository because of file size and data sensitivity considerations.

The analysis uses the following relational tables:

- `transactions` — transaction-level activity and fraud indicators
- `cards` — card-level attributes
- `users` — customer-level demographic and financial attributes

The SQL analysis was performed in PostgreSQL using joins across these tables.
