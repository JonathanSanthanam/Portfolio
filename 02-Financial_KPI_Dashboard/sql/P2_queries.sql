USE financial_kpi;

CREATE TABLE financial_raw (
    segment VARCHAR(50),
    country VARCHAR(50),
    product VARCHAR(50),
    discount_band VARCHAR(20),
    units_sold VARCHAR(20),
    manufacturing_price VARCHAR(20),
    sale_price VARCHAR(20),
    gross_sales VARCHAR(20),
    discounts VARCHAR(20),
    sales VARCHAR(20),
    cogs VARCHAR(20),
    profit VARCHAR(20),
    sale_date VARCHAR(20),
    month_number VARCHAR(5),
    month_name VARCHAR(20),
    year_val VARCHAR(5)
);

CREATE TABLE budget_raw (
    fiscal_year VARCHAR(5),
    dept VARCHAR(50),
    quarter VARCHAR(5),
    budget_usd VARCHAR(20),
    forecast_usd VARCHAR(20),
    actual_usd VARCHAR(20),
    variance_usd VARCHAR(20)
);

SELECT 'financial_raw' AS tabella, COUNT(*) AS righe FROM financial_raw
UNION ALL
SELECT 'budget_raw', COUNT(*) FROM budget_raw;

SELECT segment, country, product, discount_band,
       units_sold, gross_sales, discounts, 
       sales, cogs, profit, sale_date, year_val
FROM financial_raw
LIMIT 5;

CREATE TABLE financial_clean AS
SELECT
    TRIM(segment) AS segment,
    TRIM(country) AS country,
    TRIM(product) AS product,
    TRIM(discount_band) AS discount_band,
    CAST(REPLACE(units_sold, ',', '.') AS DECIMAL(10,2)) AS units_sold,
    CAST(REPLACE(manufacturing_price, ',', '.') AS DECIMAL(10,2)) AS manufacturing_price,
    CAST(REPLACE(sale_price, ',', '.') AS DECIMAL(10,2)) AS sale_price,
    CAST(REPLACE(gross_sales, ',', '.') AS DECIMAL(15,2)) AS gross_sales,
    CAST(REPLACE(discounts, ',', '.') AS DECIMAL(15,2)) AS discounts,
    CAST(REPLACE(sales, ',', '.') AS DECIMAL(15,2)) AS sales,
    CAST(REPLACE(cogs, ',', '.') AS DECIMAL(15,2)) AS cogs,
    CAST(REPLACE(profit, ',', '.') AS DECIMAL(15,2)) AS profit,
    STR_TO_DATE(TRIM(sale_date), '%d/%m/%Y %H:%i:%s') AS sale_date,
    CAST(month_number AS UNSIGNED) AS month_number,
    TRIM(month_name) AS month_name,
    CAST(year_val AS UNSIGNED) AS year_val
FROM financial_raw;

SELECT segment, country, product, discount_band,
       units_sold, gross_sales, discounts,
       sales, cogs, profit, sale_date, year_val
FROM financial_clean
LIMIT 5;

CREATE TABLE budget_clean AS
SELECT
    CAST(fiscal_year AS UNSIGNED) AS fiscal_year,
    TRIM(dept) AS dept,
    TRIM(quarter) AS quarter,
    CAST(REPLACE(budget_usd, ',', '.') AS DECIMAL(15,2)) AS budget_usd,
    CAST(REPLACE(forecast_usd, ',', '.') AS DECIMAL(15,2)) AS forecast_usd,
    CAST(REPLACE(actual_usd, ',', '.') AS DECIMAL(15,2)) AS actual_usd,
    CAST(REPLACE(variance_usd, ',', '.') AS DECIMAL(15,2)) AS variance_usd
FROM budget_raw;

SELECT * FROM budget_clean LIMIT 5;

ALTER TABLE financial_clean
ADD COLUMN profit_margin_pct DECIMAL(8,4),
ADD COLUMN cogs_ratio_pct DECIMAL(8,4),
ADD COLUMN discount_pct DECIMAL(8,4),
ADD COLUMN price_premium DECIMAL(8,4);

ALTER TABLE financial_clean
ADD COLUMN profit_margin_pct DECIMAL(8,4),
ADD COLUMN cogs_ratio_pct DECIMAL(8,4),
ADD COLUMN discount_pct DECIMAL(8,4),
ADD COLUMN price_premium DECIMAL(8,4);

UPDATE financial_clean
SET
    profit_margin_pct = ROUND(profit / NULLIF(sales, 0) * 100, 2),
    cogs_ratio_pct = ROUND(cogs / NULLIF(sales, 0) * 100, 2),
    discount_pct = ROUND(discounts / NULLIF(gross_sales, 0) * 100, 2),
    price_premium = ROUND(sale_price / NULLIF(manufacturing_price, 0), 2);
    
ALTER TABLE budget_clean
ADD COLUMN variance_pct DECIMAL(8,4),
ADD COLUMN budget_utilization_pct DECIMAL(8,4),
ADD COLUMN forecast_error_pct DECIMAL(8,4),
ADD COLUMN variance_flag VARCHAR(20);

UPDATE budget_clean
SET
    variance_pct = ROUND(variance_usd / NULLIF(budget_usd, 0) * 100, 2),
    budget_utilization_pct = ROUND(actual_usd / NULLIF(budget_usd, 0) * 100, 2),
    forecast_error_pct = ROUND(ABS(forecast_usd - actual_usd) / NULLIF(actual_usd, 0) * 100, 2),
    variance_flag = CASE WHEN variance_usd >= 0 THEN 'Favorable' ELSE 'Unfavorable' END;
    
SELECT
    SUM(CASE WHEN segment IS NULL THEN 1 ELSE 0 END) AS null_segment,
    SUM(CASE WHEN sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN profit IS NULL THEN 1 ELSE 0 END) AS null_profit,
    SUM(CASE WHEN sale_date IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN profit_margin_pct IS NULL THEN 1 ELSE 0 END) AS null_margin
FROM financial_clean;

SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT country) AS countries,
    COUNT(DISTINCT product) AS products,
    COUNT(DISTINCT segment) AS segments,
    ROUND(SUM(gross_sales), 0) AS total_gross_sales,
    ROUND(SUM(discounts), 0) AS total_discounts,
    ROUND(SUM(sales), 0) AS total_net_sales,
    ROUND(SUM(cogs), 0) AS total_cogs,
    ROUND(SUM(profit), 0) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS overall_profit_margin_pct
FROM financial_clean;

SELECT
    segment,
    COUNT(*) AS transactions,
    ROUND(SUM(gross_sales), 0) AS gross_sales,
    ROUND(SUM(discounts), 0) AS total_discounts,
    ROUND(SUM(sales), 0) AS net_sales,
    ROUND(SUM(cogs), 0) AS total_cogs,
    ROUND(SUM(profit), 0) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct,
    RANK() OVER (ORDER BY SUM(profit) DESC) AS profit_rank,
    RANK() OVER (ORDER BY SUM(profit) / SUM(sales) DESC) AS margin_rank
FROM financial_clean
GROUP BY segment
ORDER BY total_profit DESC;

SELECT
    country,
    ROUND(SUM(sales), 0) AS net_sales,
    ROUND(SUM(profit), 0) AS total_profit,
    ROUND(SUM(profit) / SUM(sales) * 100, 2) AS profit_margin_pct,
    ROUND(AVG(sale_price), 2) AS avg_sale_price,
    ROUND(SUM(units_sold), 0) AS total_units,
    RANK() OVER (ORDER BY SUM(profit) / SUM(sales) DESC) AS margin_rank,
    RANK() OVER (ORDER BY SUM(sales) DESC) AS volume_rank
FROM financial_clean
GROUP BY country
ORDER BY profit_margin_pct DESC;

SELECT
    month_number,
    month_name,
    ROUND(SUM(CASE WHEN year_val = 2013 THEN sales ELSE 0 END), 0) AS sales_2013,
    ROUND(SUM(CASE WHEN year_val = 2014 THEN sales ELSE 0 END), 0) AS sales_2014,
    ROUND(
        (SUM(CASE WHEN year_val = 2014 THEN sales ELSE 0 END) -
         SUM(CASE WHEN year_val = 2013 THEN sales ELSE 0 END)) /
        NULLIF(SUM(CASE WHEN year_val = 2013 THEN sales ELSE 0 END), 0) * 100, 2
    ) AS yoy_growth_pct
FROM financial_clean
GROUP BY month_number, month_name
ORDER BY month_number;

SELECT
    discount_band,
    COUNT(*) AS transactions,
    ROUND(AVG(discount_pct), 2) AS avg_discount_pct,
    ROUND(AVG(profit_margin_pct), 2) AS avg_profit_margin_pct,
    ROUND(SUM(profit), 0) AS total_profit,
    ROUND(SUM(discounts), 0) AS total_discounts_given
FROM financial_clean
GROUP BY discount_band
ORDER BY avg_discount_pct;

WITH product_pricing AS (
    SELECT
        product,
        discount_band,
        ROUND(AVG(sale_price), 2) AS avg_sale_price,
        ROUND(AVG(manufacturing_price), 2) AS avg_mfg_price,
        ROUND(AVG(price_premium), 2) AS avg_price_premium,
        ROUND(AVG(profit_margin_pct), 2) AS avg_margin_pct,
        ROUND(SUM(profit), 0) AS total_profit,
        COUNT(*) AS transactions
    FROM financial_clean
    GROUP BY product, discount_band
),
best_strategy AS (
    SELECT
        product,
        discount_band AS optimal_discount_band,
        avg_sale_price,
        avg_price_premium,
        avg_margin_pct,
        total_profit,
        RANK() OVER (PARTITION BY product ORDER BY avg_margin_pct DESC) AS rk
    FROM product_pricing
)
SELECT
    product,
    optimal_discount_band,
    avg_sale_price,
    avg_price_premium,
    avg_margin_pct,
    total_profit
FROM best_strategy
WHERE rk = 1
ORDER BY avg_margin_pct DESC;

SELECT
    dept,
    ROUND(AVG(ABS(budget_usd - actual_usd) / NULLIF(actual_usd, 0) * 100), 2) AS avg_budget_error_pct,
    ROUND(AVG(ABS(forecast_usd - actual_usd) / NULLIF(actual_usd, 0) * 100), 2) AS avg_forecast_error_pct,
    ROUND(AVG(ABS(budget_usd - actual_usd) / NULLIF(actual_usd, 0) * 100) -
          AVG(ABS(forecast_usd - actual_usd) / NULLIF(actual_usd, 0) * 100), 2) AS forecast_improvement_pct,
    SUM(CASE WHEN ABS(forecast_usd - actual_usd) < ABS(budget_usd - actual_usd) THEN 1 ELSE 0 END) AS quarters_forecast_wins,
    COUNT(*) AS total_quarters
FROM budget_clean
GROUP BY dept
ORDER BY forecast_improvement_pct DESC;

WITH dept_summary AS (
    SELECT
        dept,
        fiscal_year,
        ROUND(SUM(budget_usd), 0) AS total_budget,
        ROUND(SUM(actual_usd), 0) AS total_actual,
        ROUND(SUM(variance_usd), 0) AS total_variance,
        ROUND(SUM(variance_usd) / SUM(budget_usd) * 100, 2) AS variance_pct
    FROM budget_clean
    GROUP BY dept, fiscal_year
),
what_if AS (
    SELECT
        dept,
        fiscal_year,
        total_budget,
        total_actual,
        total_variance,
        variance_pct,
        CASE WHEN variance_pct > 0 THEN 'Under Budget' ELSE 'Over Budget' END AS budget_status,
        CASE WHEN variance_pct > 0 THEN ROUND(total_budget * 0.90, 0) ELSE total_budget END AS simulated_budget,
        CASE WHEN variance_pct > 0 THEN ROUND(total_actual - (total_budget * 0.90), 0) ELSE total_variance END AS simulated_variance
    FROM dept_summary
)
SELECT
    dept,
    fiscal_year,
    budget_status,
    total_budget,
    simulated_budget,
    total_budget - simulated_budget AS budget_reduction,
    total_variance AS current_variance,
    simulated_variance AS new_variance
FROM what_if
ORDER BY budget_status DESC, dept;

CREATE VIEW financial_export AS
SELECT * FROM financial_clean;

CREATE VIEW budget_export AS
SELECT * FROM budget_clean;

SELECT * FROM budget_export;

SELECT SUM(sales) FROM financial_clean;