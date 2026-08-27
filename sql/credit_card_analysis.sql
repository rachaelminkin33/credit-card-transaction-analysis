-- ============================================================
-- CREDIT CARD TRANSACTION ANALYSIS
-- ============================================================
-- Dataset: IBM Credit Card Transactions
-- Database: PostgreSQL
--
-- Project goal:
-- Analyze transaction behavior, card usage, customer
-- characteristics, and observed fraud patterns.
--
-- Analysis uses a 500,000-transaction sample from the
-- full transaction dataset for portfolio analysis.
--
-- Skills Demonstrated:
-- - Data validation
-- - Relational joins
-- - Common Table Expressions (CTEs)
-- - CASE-based segmentation
-- - Conditional aggregation
-- - Fraud-rate calculations
-- - Customer-level analysis
-- - Reusable SQL views
--
-- Note:
-- Results represent observed patterns within the analyzed
-- sample and should not be interpreted as causal relationships
-- or predictive fraud models.
-- ============================================================


-- ============================================================
-- 1. DATA VALIDATION
-- ============================================================

-- Confirm transaction volume
SELECT COUNT(*) AS total_transactions
FROM transactions;


-- Check for missing values in key transaction fields
SELECT
    COUNT(*) AS total_rows,
    COUNT(user_id) AS user_rows,
    COUNT(card_index) AS card_rows,
    COUNT(amount) AS amount_rows,
    COUNT(use_chip) AS chip_rows,
    COUNT(is_fraud) AS fraud_rows
FROM transactions;


-- Confirm card records
SELECT COUNT(*) AS total_cards
FROM cards;


-- Check for missing values in key card fields
SELECT
    COUNT(*) AS total_cards,
    COUNT(*) - COUNT(user_id) AS missing_user_id,
    COUNT(*) - COUNT(card_index) AS missing_card_index,
    COUNT(*) - COUNT(card_brand) AS missing_brand,
    COUNT(*) - COUNT(card_type) AS missing_type,
    COUNT(*) - COUNT(credit_limit) AS missing_credit_limit,
    COUNT(*) - COUNT(card_on_dark_web) AS missing_dark_web
FROM cards;


-- Confirm customer records
SELECT COUNT(*) AS total_customers
FROM users;


-- Confirm customer IDs are unique
SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT user_id) AS unique_user_ids
FROM users;


-- ============================================================
-- 2. CUSTOMER ANALYSIS
-- ============================================================

-- Business question:
-- Do transaction patterns differ across customer income groups?
--
-- Note: The transaction sample represents a limited subset of
-- customers, so these results should be treated as exploratory.


WITH income_groups AS (
    SELECT
        user_id,
        CASE
            WHEN yearly_income_person < 30000 THEN 'Under $30K'
            WHEN yearly_income_person < 50000 THEN '$30K-$49K'
            WHEN yearly_income_person < 75000 THEN '$50K-$74K'
            WHEN yearly_income_person < 100000 THEN '$75K-$99K'
            ELSE '$100K+'
        END AS income_group
    FROM users
)
SELECT
    i.income_group,
    COUNT(DISTINCT i.user_id) AS customers,
    COUNT(*) AS transactions,
    ROUND(SUM(t.amount), 2) AS total_spending,
    ROUND(AVG(t.amount), 2) AS average_transaction
FROM transactions t
JOIN income_groups i
    ON t.user_id = i.user_id
GROUP BY i.income_group
ORDER BY
    CASE i.income_group
        WHEN 'Under $30K' THEN 1
        WHEN '$30K-$49K' THEN 2
        WHEN '$50K-$74K' THEN 3
        WHEN '$75K-$99K' THEN 4
        WHEN '$100K+' THEN 5
    END;


-- ============================================================
-- 3. CARD ANALYSIS
-- ============================================================

-- Business question:
-- Does average transaction size differ by card type?


SELECT
    c.card_type,
    COUNT(*) AS transaction_count,
    ROUND(SUM(t.amount), 2) AS total_spending,
    ROUND(AVG(t.amount), 2) AS average_transaction
FROM transactions t
JOIN cards c
    ON t.user_id = c.user_id
    AND t.card_index = c.card_index
GROUP BY c.card_type
ORDER BY average_transaction DESC;


-- Business question:
-- Does observed fraud rate differ by card type?


SELECT
    c.card_type,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        3
    ) AS fraud_rate
FROM transactions t
JOIN cards c
    ON t.user_id = c.user_id
    AND t.card_index = c.card_index
GROUP BY c.card_type
ORDER BY fraud_rate DESC;


-- ============================================================
-- 4. TRANSACTION ANALYSIS
-- ============================================================

-- Business question:
-- Does transaction size differ by payment method?


SELECT
    use_chip,
    COUNT(*) AS transaction_count,
    ROUND(SUM(amount), 2) AS total_spending,
    ROUND(AVG(amount), 2) AS average_transaction
FROM transactions
GROUP BY use_chip
ORDER BY average_transaction DESC;


-- Business question:
-- Which payment methods have the highest observed fraud rates?


SELECT
    use_chip,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN is_fraud = 'Yes' THEN 1 ELSE 0 END)
        AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        3
    ) AS fraud_rate
FROM transactions
GROUP BY use_chip
ORDER BY fraud_rate DESC;


-- ============================================================
-- 5. FRAUD ANALYSIS
-- ============================================================

-- Business question:
-- Does observed fraud rate differ by card brand?


SELECT
    c.card_brand,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        3
    ) AS fraud_rate
FROM transactions t
JOIN cards c
    ON t.user_id = c.user_id
    AND t.card_index = c.card_index
GROUP BY c.card_brand
ORDER BY fraud_rate DESC;


-- Business question:
-- Does observed fraud rate differ across customer FICO groups?


WITH fico_groups AS (
    SELECT
        user_id,
        CASE
            WHEN fico_score < 580 THEN 'Poor (<580)'
            WHEN fico_score < 670 THEN 'Fair (580-669)'
            WHEN fico_score < 740 THEN 'Good (670-739)'
            WHEN fico_score < 800 THEN 'Very Good (740-799)'
            ELSE 'Exceptional (800+)'
        END AS fico_group
    FROM users
)
SELECT
    f.fico_group,
    COUNT(*) AS total_transactions,
    SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        3
    ) AS fraud_rate
FROM transactions t
JOIN fico_groups f
    ON t.user_id = f.user_id
GROUP BY f.fico_group
ORDER BY fraud_rate DESC;


-- ============================================================
-- 6. COMBINED CUSTOMER-LEVEL ANALYSIS
-- ============================================================

-- Business question:
-- How do customer income and credit score relate to transaction
-- behavior and observed fraud?
--
-- This analysis combines customer, card, and transaction data.
-- Results should be interpreted as observed patterns, not causal
-- relationships.


WITH customer_profiles AS (
    SELECT
        user_id,
        CASE
            WHEN yearly_income_person < 30000 THEN 'Under $30K'
            WHEN yearly_income_person < 50000 THEN '$30K-$49K'
            WHEN yearly_income_person < 75000 THEN '$50K-$74K'
            WHEN yearly_income_person < 100000 THEN '$75K-$99K'
            ELSE '$100K+'
        END AS income_group,
        CASE
            WHEN fico_score < 580 THEN 'Poor (<580)'
            WHEN fico_score < 670 THEN 'Fair (580-669)'
            WHEN fico_score < 740 THEN 'Good (670-739)'
            WHEN fico_score < 800 THEN 'Very Good (740-799)'
            ELSE 'Exceptional (800+)'
        END AS fico_group
    FROM users
)
SELECT
    p.income_group,
    p.fico_group,
    COUNT(*) AS transactions,
    ROUND(AVG(t.amount), 2) AS average_transaction,
    ROUND(
        100.0 * SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        3
    ) AS fraud_rate
FROM transactions t
JOIN cards c
    ON t.user_id = c.user_id
    AND t.card_index = c.card_index
JOIN customer_profiles p
    ON t.user_id = p.user_id
GROUP BY
    p.income_group,
    p.fico_group
ORDER BY
    p.income_group,
    p.fico_group;

-- ============================================================
-- 7. POWER BI ANALYSIS VIEWS
-- ============================================================

-- View: Fraud rate by payment method
CREATE OR REPLACE VIEW vw_payment_method_fraud AS
SELECT
    use_chip AS payment_method,
    COUNT(*) AS transactions,
    SUM(CASE WHEN is_fraud = 'Yes' THEN 1 ELSE 0 END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        3
    ) AS fraud_rate
FROM transactions
GROUP BY use_chip;


-- View: Fraud rate by card type
CREATE OR REPLACE VIEW vw_card_type_fraud AS
SELECT
    c.card_type,
    COUNT(*) AS transactions,
    SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        3
    ) AS fraud_rate
FROM transactions t
JOIN cards c
    ON t.user_id = c.user_id
    AND t.card_index = c.card_index
GROUP BY c.card_type;


-- View: Fraud rate by FICO group
CREATE OR REPLACE VIEW vw_fico_fraud AS
SELECT
    CASE
        WHEN u.fico_score < 580 THEN 'Poor (<580)'
        WHEN u.fico_score < 670 THEN 'Fair (580-669)'
        WHEN u.fico_score < 740 THEN 'Good (670-739)'
        WHEN u.fico_score < 800 THEN 'Very Good (740-799)'
        ELSE 'Exceptional (800+)'
    END AS fico_group,
    COUNT(*) AS transactions,
    SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END) AS fraudulent_transactions,
    ROUND(
        100.0 * SUM(CASE WHEN t.is_fraud = 'Yes' THEN 1 ELSE 0 END)
        / COUNT(*),
        3
    ) AS fraud_rate
FROM transactions t
JOIN users u
    ON t.user_id = u.user_id
GROUP BY fico_group;


-- View: Spending by customer income group
CREATE OR REPLACE VIEW vw_income_spending AS
SELECT
    CASE
        WHEN u.yearly_income_person < 30000 THEN 'Under $30K'
        WHEN u.yearly_income_person < 50000 THEN '$30K-$49K'
        WHEN u.yearly_income_person < 75000 THEN '$50K-$74K'
        WHEN u.yearly_income_person < 100000 THEN '$75K-$99K'
        ELSE '$100K+'
    END AS income_group,
    COUNT(*) AS transactions,
    ROUND(SUM(t.amount), 2) AS total_spending,
    ROUND(AVG(t.amount), 2) AS average_transaction
FROM transactions t
JOIN users u
    ON t.user_id = u.user_id
GROUP BY income_group;


-- View: Spending by card type
CREATE OR REPLACE VIEW vw_card_type_spending AS
SELECT
    c.card_type,
    COUNT(*) AS transactions,
    ROUND(SUM(t.amount), 2) AS total_spending,
    ROUND(AVG(t.amount), 2) AS average_transaction
FROM transactions t
JOIN cards c
    ON t.user_id = c.user_id
    AND t.card_index = c.card_index
GROUP BY c.card_type;
