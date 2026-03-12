
-- Advanced Data Analytics with PostgreSQL
-- Superstore Sales Portfolio Project
-- Student: Sahro Haji
-- Dataset file: cleaned_superstore_sales.csv
-- Note:
-- 1. Replace the file path in the COPY command with your local file path.
-- 2. Run each numbered section in PostgreSQL.
-- 3. Capture screenshots for every query marked SCREENSHOT.

DROP TABLE IF EXISTS superstore_sales;

-- SECTION 1: Database creation and schema design  SCREENSHOT
CREATE TABLE superstore_sales (
    row_id SERIAL PRIMARY KEY,
    ship_mode VARCHAR(30) NOT NULL,
    segment VARCHAR(30) NOT NULL,
    country VARCHAR(50) NOT NULL,
    city VARCHAR(80) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code INTEGER,
    region VARCHAR(20) NOT NULL,
    category VARCHAR(30) NOT NULL,
    sub_category VARCHAR(30) NOT NULL,
    sales NUMERIC(12,2) NOT NULL,
    quantity INTEGER NOT NULL,
    discount NUMERIC(4,2) NOT NULL,
    profit NUMERIC(12,2) NOT NULL
);

-- Schema rationale:
-- This table stores one transaction level record per row.
-- Text data types are used for descriptive categorical fields.
-- NUMERIC types are used for financial values to preserve precision.
-- INTEGER is used for quantity and postal code.
-- A surrogate primary key is added because the cleaned file does not include a native transaction key.

-- SECTION 2: Load the cleaned CSV file  SCREENSHOT
COPY superstore_sales (
    ship_mode, segment, country, city, state, postal_code,
    region, category, sub_category, sales, quantity, discount, profit
)
FROM 'C:/replace_with_your_path/cleaned_superstore_sales.csv'
DELIMITER ','
CSV HEADER;

-- SECTION 3: Data validation  SCREENSHOT
-- 3A. Confirm row count
SELECT COUNT(*) AS total_rows
FROM superstore_sales;

-- 3B. Check for missing values in every column
SELECT
    SUM(CASE WHEN ship_mode IS NULL THEN 1 ELSE 0 END) AS null_ship_mode,
    SUM(CASE WHEN segment IS NULL THEN 1 ELSE 0 END) AS null_segment,
    SUM(CASE WHEN country IS NULL THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END) AS null_state,
    SUM(CASE WHEN postal_code IS NULL THEN 1 ELSE 0 END) AS null_postal_code,
    SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END) AS null_region,
    SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END) AS null_category,
    SUM(CASE WHEN sub_category IS NULL THEN 1 ELSE 0 END) AS null_sub_category,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS null_quantity,
    SUM(CASE WHEN discount IS NULL THEN 1 ELSE 0 END) AS null_discount,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END) AS null_profit
FROM superstore_sales;

-- 3C. Check repeated rows across business fields
SELECT
    ship_mode, segment, country, city, state, postal_code, region,
    category, sub_category, sales, quantity, discount, profit,
    COUNT(*) AS duplicate_count
FROM superstore_sales
GROUP BY
    ship_mode, segment, country, city, state, postal_code, region,
    category, sub_category, sales, quantity, discount, profit
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, sales DESC;

-- SECTION 4: Summary statistics  SCREENSHOT
SELECT
    COUNT(*) AS total_transactions,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(sales), 2) AS average_sales,
    ROUND(AVG(profit), 2) AS average_profit,
    ROUND(STDDEV_SAMP(sales), 2) AS sales_std_dev,
    ROUND(100.0 * SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) / COUNT(*), 2) AS percent_loss_transactions
FROM superstore_sales;

-- SECTION 5: Exploratory data analysis queries

-- 5A. Regional performance  SCREENSHOT
SELECT
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_percent
FROM superstore_sales
GROUP BY region
ORDER BY total_profit DESC;

-- 5B. Category performance  SCREENSHOT
SELECT
    category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_percent,
    ROUND(AVG(discount), 3) AS average_discount
FROM superstore_sales
GROUP BY category
ORDER BY total_profit DESC;

-- 5C. Profitability by discount band  SCREENSHOT
SELECT
    CASE
        WHEN discount = 0 THEN 'No discount'
        WHEN discount > 0 AND discount <= 0.10 THEN 'Low discount'
        WHEN discount > 0.10 AND discount <= 0.20 THEN 'Moderate discount'
        WHEN discount > 0.20 AND discount <= 0.30 THEN 'High discount'
        ELSE 'Very high discount'
    END AS discount_band,
    COUNT(*) AS transactions,
    ROUND(AVG(profit), 2) AS average_profit,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore_sales
GROUP BY
    CASE
        WHEN discount = 0 THEN 'No discount'
        WHEN discount > 0 AND discount <= 0.10 THEN 'Low discount'
        WHEN discount > 0.10 AND discount <= 0.20 THEN 'Moderate discount'
        WHEN discount > 0.20 AND discount <= 0.30 THEN 'High discount'
        ELSE 'Very high discount'
    END
ORDER BY average_profit DESC;

-- SECTION 6: Advanced research questions and queries

-- Research Question 1
-- Which product categories and subcategories generate the highest total sales and total profit?
-- 6A. Category and subcategory performance  SCREENSHOT
SELECT
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(*) AS transactions
FROM superstore_sales
GROUP BY category, sub_category
ORDER BY total_profit DESC, total_sales DESC;

-- Research Question 2
-- Which regions and states generate the highest and lowest profit margins?
-- 6B. State profit margin analysis  SCREENSHOT
SELECT
    state,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_percent
FROM superstore_sales
GROUP BY state
HAVING SUM(sales) >= 20000
ORDER BY profit_margin_percent DESC;

-- Research Question 3
-- How do discounts affect profit across different product categories and subcategories?
-- 6C. Discount effect by category  SCREENSHOT
SELECT
    category,
    ROUND(AVG(discount), 3) AS average_discount,
    ROUND(AVG(profit), 2) AS average_profit,
    ROUND(SUM(profit), 2) AS total_profit
FROM superstore_sales
GROUP BY category
ORDER BY average_profit DESC;

-- Research Question 4
-- Which customer segments generate the highest total revenue and profit?
-- 6D. Segment analysis  SCREENSHOT
SELECT
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_percent
FROM superstore_sales
GROUP BY segment
ORDER BY total_profit DESC;

-- Research Question 5
-- Which products generate high sales but low or negative profit?
-- 6E. High sales and low profit subcategories  SCREENSHOT
SELECT
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(discount), 3) AS average_discount
FROM superstore_sales
GROUP BY sub_category
HAVING SUM(sales) > (
    SELECT AVG(sub_sales)
    FROM (
        SELECT SUM(sales) AS sub_sales
        FROM superstore_sales
        GROUP BY sub_category
    ) AS subquery_sales
)
AND SUM(profit) < 5000
ORDER BY total_sales DESC;

-- Research Question 6
-- How does shipping mode impact profit and delivery related performance?
-- 6F. Shipping mode analysis  SCREENSHOT
SELECT
    ship_mode,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit), 2) AS average_profit,
    ROUND(100.0 * SUM(profit) / NULLIF(SUM(sales), 0), 2) AS profit_margin_percent
FROM superstore_sales
GROUP BY ship_mode
ORDER BY total_profit DESC;

-- Research Question 7
-- Which combinations of region, category, and customer segment produce the highest profit?
-- 6G. Combination profitability with a window function  SCREENSHOT
SELECT
    region,
    category,
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
FROM superstore_sales
GROUP BY region, category, segment
ORDER BY profit_rank, total_sales DESC;

-- Research Question 8
-- Which regions rank highest in profit and sales overall?
-- 6H. Regional ranking with window functions  SCREENSHOT
SELECT
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    RANK() OVER (ORDER BY SUM(sales) DESC) AS sales_rank,
    RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
FROM superstore_sales
GROUP BY region
ORDER BY profit_rank;

-- SECTION 7: Performance optimization
-- Add indexes to support common grouping and filtering patterns  SCREENSHOT
CREATE INDEX idx_superstore_region ON superstore_sales(region);
CREATE INDEX idx_superstore_category ON superstore_sales(category);
CREATE INDEX idx_superstore_segment ON superstore_sales(segment);
CREATE INDEX idx_superstore_discount ON superstore_sales(discount);

-- Verify performance plan for one advanced query  SCREENSHOT
EXPLAIN ANALYZE
SELECT
    region,
    category,
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank
FROM superstore_sales
GROUP BY region, category, segment
ORDER BY profit_rank, total_sales DESC;
