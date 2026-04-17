-- ================================================================
-- UK POST-BREXIT TRADE INTELLIGENCE PLATFORM
-- Complete SQL KPI Analysis — 2016 to 2024
-- Database: richlist
-- Tables: table1_trade_by_country, table2_trade_by_product
-- ================================================================

-- ================================================================
-- KPI 1: Total Trade Pre vs Post Brexit
-- Business Question: Has total UK trade increased or decreased?
-- ================================================================

SELECT
    Brexit_Period,
    COUNT(DISTINCT Year) AS Years,
    ROUND(SUM(Exports_GBP_Millions), 2) AS Sum_Exports,
    ROUND(SUM(Imports_GBP_Millions), 2) AS Sum_Imports,
    ROUND(SUM(Exports_GBP_Millions) - SUM(Imports_GBP_Millions), 2) AS Trade_Balance
FROM table1_trade_by_country
GROUP BY Brexit_Period
ORDER BY Trade_Balance ASC;


-- ================================================================
-- KPI 2: EU vs Non-EU Split
-- Business Question: Is UK becoming less dependent on EU trade?
-- Which Non-EU countries are replacing EU trade?
-- ================================================================

SELECT
    COUNT(DISTINCT Year) AS Years,
    EU_NonEU,
    Brexit_Period,
    ROUND(SUM(Exports_GBP_Millions), 2) AS Sum_Exports,
    ROUND(SUM(Imports_GBP_Millions), 2) AS Sum_Imports,
    ROUND(SUM(Exports_GBP_Millions) - SUM(Imports_GBP_Millions), 2) AS Trade_Balance
FROM table1_trade_by_country
GROUP BY EU_NonEU, Brexit_Period
ORDER BY Sum_Exports DESC;


-- ================================================================
-- KPI 3: Trade Balance by Country
-- Business Question: Which countries does UK have biggest deficit/surplus with?
-- ================================================================

SELECT
    COUNT(DISTINCT Year) AS Years,
    Country,
    ROUND(SUM(Exports_GBP_Millions), 2) AS Sum_Exports,
    ROUND(SUM(Imports_GBP_Millions), 2) AS Sum_Imports,
    ROUND(SUM(Exports_GBP_Millions) - SUM(Imports_GBP_Millions), 2) AS Trade_Balance
FROM table1_trade_by_country
GROUP BY Country
ORDER BY Trade_Balance DESC
LIMIT 10;


-- ================================================================
-- KPI 4: Top 10 Export Destinations
-- Business Question: Who buys the most from UK?
-- ================================================================

SELECT
    COUNT(DISTINCT Year) AS Years,
    Country,
    ROUND(SUM(Exports_GBP_Millions), 2) AS Sum_Exports,
    ROUND(SUM(Imports_GBP_Millions), 2) AS Sum_Imports,
    ROUND(SUM(Exports_GBP_Millions) - SUM(Imports_GBP_Millions), 2) AS Trade_Balance
FROM table1_trade_by_country
GROUP BY Country
ORDER BY Sum_Exports DESC
LIMIT 10;


-- ================================================================
-- KPI 5: Top 10 Import Sources
-- Business Question: Who sells the most TO UK?
-- ================================================================

SELECT
    COUNT(DISTINCT Year) AS Years,
    Country,
    ROUND(SUM(Exports_GBP_Millions), 2) AS Sum_Exports,
    ROUND(SUM(Imports_GBP_Millions), 2) AS Sum_Imports,
    ROUND(SUM(Exports_GBP_Millions) - SUM(Imports_GBP_Millions), 2) AS Trade_Balance
FROM table1_trade_by_country
GROUP BY Country
ORDER BY Sum_Imports DESC
LIMIT 10;


-- ================================================================
-- KPI 6: Year on Year Export Growth %
-- Business Question: Is trade growing or shrinking each year?
-- ================================================================

WITH yearly_totals AS (
    SELECT
        Year,
        ROUND(SUM(Exports_GBP_Millions), 2) AS total_exports
    FROM table1_trade_by_country
    GROUP BY Year
)
SELECT
    Year,
    total_exports,
    LAG(total_exports, 1) OVER (ORDER BY Year) AS prev_year_exports,
    ROUND(
        (total_exports - LAG(total_exports, 1) OVER (ORDER BY Year))
        / LAG(total_exports, 1) OVER (ORDER BY Year) * 100
    , 2) AS growth_pct
FROM yearly_totals
ORDER BY Year;


-- ================================================================
-- KPI 7: Best Performing Product Sector
-- Business Question: Which product sector leads UK exports?
-- ================================================================

SELECT
    Product_Category,
    ROUND(SUM(Exports_GBP_Millions), 2) AS Sum_Exports
FROM table2_trade_by_product
GROUP BY Product_Category
ORDER BY Sum_Exports DESC;


-- ================================================================
-- KPI 8: Worst Performing Product Post Brexit
-- Business Question: Which sector suffered most post Brexit?
-- ================================================================

SELECT
    Product_Category,
    ROUND(SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
        THEN Exports_GBP_Millions ELSE 0 END), 2) AS Pre_Brexit,
    ROUND(SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
        THEN Exports_GBP_Millions ELSE 0 END), 2) AS Post_Brexit,
    ROUND(
        SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
            THEN Exports_GBP_Millions ELSE 0 END)
        -
        SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
            THEN Exports_GBP_Millions ELSE 0 END)
    , 2) AS diff
FROM table2_trade_by_product
GROUP BY Product_Category
ORDER BY diff ASC;


-- ================================================================
-- KPI 9: Trade Concentration HHI
-- Business Question: How risky is UK trade dependency?
-- ================================================================

WITH country_exports AS (
    SELECT
        Country,
        SUM(Exports_GBP_Millions) AS total_exports
    FROM table1_trade_by_country
    GROUP BY Country
),
total AS (
    SELECT SUM(Exports_GBP_Millions) AS grand_total
    FROM table1_trade_by_country
),
market_share AS (
    SELECT
        c.Country,
        ROUND(c.total_exports / t.grand_total * 100, 4) AS share_pct
    FROM country_exports c, total t
)
SELECT
    Country,
    share_pct,
    ROUND(POWER(share_pct, 2), 4) AS share_squared,
    SUM(ROUND(POWER(share_pct, 2), 4)) OVER () AS HHI_Score
FROM market_share
ORDER BY share_pct DESC;


-- ================================================================
-- KPI 10: Fastest Growing Non-EU Market
-- Business Question: Where is the biggest opportunity post Brexit?
-- ================================================================

SELECT
    Country,
    EU_NonEU,
    ROUND(SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
        THEN Exports_GBP_Millions ELSE 0 END), 2) AS Pre_Brexit_Exports,
    ROUND(SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
        THEN Exports_GBP_Millions ELSE 0 END), 2) AS Post_Brexit_Exports,
    ROUND(
        (SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
            THEN Exports_GBP_Millions ELSE 0 END)
        - SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
            THEN Exports_GBP_Millions ELSE 0 END))
        / NULLIF(SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
            THEN Exports_GBP_Millions ELSE 0 END), 0) * 100
    , 2) AS Growth_Pct
FROM table1_trade_by_country
WHERE EU_NonEU = 'Non-EU'
GROUP BY Country, EU_NonEU
ORDER BY Growth_Pct DESC
LIMIT 10;


-- ================================================================
-- KPI 11: Brexit Impact Score by Country
-- Business Question: Which countries were most affected by Brexit?
-- ================================================================

SELECT
    Country,
    ROUND(SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
        THEN Exports_GBP_Millions + Imports_GBP_Millions
        ELSE 0 END), 2) AS Pre_Brexit,
    ROUND(SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
        THEN Exports_GBP_Millions + Imports_GBP_Millions
        ELSE 0 END), 2) AS Post_Brexit,
    ROUND((SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
        THEN Exports_GBP_Millions + Imports_GBP_Millions
        ELSE 0 END)
    - SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
        THEN Exports_GBP_Millions + Imports_GBP_Millions
        ELSE 0 END)), 2) AS diff,
    RANK() OVER (ORDER BY (
        SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
            THEN Exports_GBP_Millions + Imports_GBP_Millions
            ELSE 0 END)
        - SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
            THEN Exports_GBP_Millions + Imports_GBP_Millions
            ELSE 0 END)
    ) DESC) AS rownum
FROM table1_trade_by_country
GROUP BY Country;


-- ================================================================
-- KPI 12: Product Performance Pre vs Post Brexit
-- Business Question: Which products grew or declined post Brexit?
-- ================================================================

SELECT
    Product_Category,
    EU_NonEU,
    ROUND(SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
        THEN Exports_GBP_Millions ELSE 0 END), 2) AS Pre_Brexit,
    ROUND(SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
        THEN Exports_GBP_Millions ELSE 0 END), 2) AS Post_Brexit,
    ROUND(
        SUM(CASE WHEN Brexit_Period = 'Post-Brexit'
            THEN Exports_GBP_Millions ELSE 0 END)
        -
        SUM(CASE WHEN Brexit_Period = 'Pre-Brexit'
            THEN Exports_GBP_Millions ELSE 0 END)
    , 2) AS diff
FROM table2_trade_by_product
GROUP BY Product_Category, EU_NonEU
ORDER BY diff ASC;


-- ================================================================
-- ADVANCED KPIs — Using Additional Datasets
-- ================================================================

-- ================================================================
-- KPI 13: Currency Impact — When Did GBP Weaken Most?
-- ================================================================

SELECT
    Year,
    GBP_USD,
    Brexit_Period,
    RANK() OVER (ORDER BY GBP_USD ASC) AS rnk
FROM dataset3_gbp_exchange_rates
WHERE Brexit_Period = 'Post-Brexit'
GROUP BY Year, GBP_USD, Brexit_Period;


-- ================================================================
-- KPI 13B: Currency Volatility by Pair
-- ================================================================

WITH cte AS (
    SELECT
        Year,
        SUM(GBP_EUR) AS summ,
        LEAD(SUM(GBP_EUR), 1) OVER (ORDER BY Year) AS next_year,
        ROUND(
            (SUM(GBP_EUR) - LEAD(SUM(GBP_EUR), 1) OVER (ORDER BY Year))
            / LEAD(SUM(GBP_EUR), 1) OVER (ORDER BY Year) * 100
        , 2) AS diffperc
    FROM dataset3_gbp_exchange_rates
    GROUP BY Year
)
SELECT SUM(ABS(diffperc)) AS volatility_GEur
FROM cte;


-- ================================================================
-- KPI 14: Economic Context — GDP and Export Growth
-- Business Question: Which years showed both GDP and export growth?
-- ================================================================

WITH cte AS (
    SELECT
        SUM(table1_trade_by_country.Exports_GBP_Millions) AS summ,
        table1_trade_by_country.Year,
        SUM(dataset4_uk_economic_indicators.GDP_GBP_Billions) AS summm,
        LAG(SUM(table1_trade_by_country.Exports_GBP_Millions), 1)
            OVER (ORDER BY table1_trade_by_country.Year) AS prev_year,
        LAG(SUM(dataset4_uk_economic_indicators.GDP_GBP_Billions), 1)
            OVER (ORDER BY table1_trade_by_country.Year) AS prev_year2,
        (SUM(table1_trade_by_country.Exports_GBP_Millions)
            - LAG(SUM(table1_trade_by_country.Exports_GBP_Millions), 1)
            OVER (ORDER BY table1_trade_by_country.Year)) AS diff,
        (SUM(dataset4_uk_economic_indicators.GDP_GBP_Billions)
            - LAG(SUM(dataset4_uk_economic_indicators.GDP_GBP_Billions), 1)
            OVER (ORDER BY table1_trade_by_country.Year)) AS diff2
    FROM table1_trade_by_country
    LEFT JOIN dataset4_uk_economic_indicators
        ON dataset4_uk_economic_indicators.Year = table1_trade_by_country.Year
    GROUP BY table1_trade_by_country.Year,
             dataset4_uk_economic_indicators.GDP_GBP_Billions
)
SELECT *
FROM cte
WHERE diff > 0 AND diff2 > 0;


-- ================================================================
-- KPI 15: FTA Impact — Did UK exports grow to FTA countries?
-- ================================================================

WITH cte AS (
    SELECT
        table1_trade_by_country.Country,
        table1_trade_by_country.Exports_GBP_Millions,
        table1_trade_by_country.Year,
        dataset5_uk_trade_agreements.Year_Signed
    FROM table1_trade_by_country
    JOIN dataset5_uk_trade_agreements
        ON dataset5_uk_trade_agreements.Country = table1_trade_by_country.Country
    GROUP BY
        table1_trade_by_country.Country,
        table1_trade_by_country.Exports_GBP_Millions,
        table1_trade_by_country.Year,
        dataset5_uk_trade_agreements.Year_Signed
)
SELECT
    Country,
    SUM(CASE WHEN Year < Year_Signed
        THEN Exports_GBP_Millions END) AS post_exports,
    SUM(CASE WHEN Year > Year_Signed
        THEN Exports_GBP_Millions END) AS pre_exports,
    CASE
        WHEN SUM(CASE WHEN Year > Year_Signed
            THEN Exports_GBP_Millions END)
            > SUM(CASE WHEN Year < Year_Signed
            THEN Exports_GBP_Millions END)
        THEN 'decreased'
        WHEN SUM(CASE WHEN Year > Year_Signed
            THEN Exports_GBP_Millions END)
            < SUM(CASE WHEN Year < Year_Signed
            THEN Exports_GBP_Millions END)
        THEN 'Increased'
        ELSE 'null'
    END AS result
FROM cte
GROUP BY Country;


-- ================================================================
-- KPI 15B: Which FTA delivered highest export value?
-- ================================================================

WITH cte AS (
    SELECT
        ROUND(SUM(table1_trade_by_country.Exports_GBP_Millions)) AS summ,
        table1_trade_by_country.Country,
        dataset5_uk_trade_agreements.Agreement_Type,
        dataset5_uk_trade_agreements.Agreement_Name,
        DENSE_RANK() OVER (
            ORDER BY SUM(table1_trade_by_country.Exports_GBP_Millions) DESC
        ) AS rnk
    FROM table1_trade_by_country
    JOIN dataset5_uk_trade_agreements
        ON dataset5_uk_trade_agreements.Country = table1_trade_by_country.Country
    GROUP BY
        table1_trade_by_country.Country,
        dataset5_uk_trade_agreements.Agreement_Type,
        dataset5_uk_trade_agreements.Agreement_Name
)
SELECT *
FROM cte
WHERE Agreement_Type = 'FTA';


-- ================================================================
-- KPI 16: Partner GDP vs UK Exports
-- Business Question: Which countries are underserved vs their GDP?
-- ================================================================

WITH cte AS (
    SELECT
        dataset6_trading_partner_gdp.Country,
        AVG(dataset6_trading_partner_gdp.GDP_USD_Billions) AS average_gdp,
        SUM(table1_trade_by_country.Exports_GBP_Millions) AS sum_export
    FROM dataset6_trading_partner_gdp
    JOIN table1_trade_by_country
        ON dataset6_trading_partner_gdp.Country = table1_trade_by_country.Country
    GROUP BY dataset6_trading_partner_gdp.Country
)
SELECT *
FROM cte;
