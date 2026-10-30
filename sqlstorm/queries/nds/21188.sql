
WITH RankedSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sales_price,
        cs.cs_sales_price,
        ss.ss_sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS rnk_web,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cs.cs_sales_price DESC) AS rnk_catalog,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ss.ss_sales_price DESC) AS rnk_store
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
),
AggregatedSales AS (
    SELECT 
        c_customer_sk,
        SUM(ws_sales_price) AS total_web_sales,
        SUM(cs_sales_price) AS total_catalog_sales,
        SUM(ss_sales_price) AS total_store_sales
    FROM RankedSales
    GROUP BY c_customer_sk
),
IncomeDemographics AS (
    SELECT
        hd.hd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_demo_sk ORDER BY ib.ib_lower_bound) AS income_rank
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT
    c.c_customer_id,
    COALESCE(tws.total_web_sales, 0) AS total_web_sales,
    COALESCE(tcs.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(tss.total_store_sales, 0) AS total_store_sales,
    CASE 
        WHEN COALESCE(tws.total_web_sales, 0) > COALESCE(tcs.total_catalog_sales, 0) 
             AND COALESCE(tws.total_web_sales, 0) > COALESCE(tss.total_store_sales, 0) THEN 'Web Dominant'
        WHEN COALESCE(tcs.total_catalog_sales, 0) > COALESCE(tws.total_web_sales, 0) 
             AND COALESCE(tcs.total_catalog_sales, 0) > COALESCE(tss.total_store_sales, 0) THEN 'Catalog Dominant'
        WHEN COALESCE(tss.total_store_sales, 0) > COALESCE(tws.total_web_sales, 0) 
             AND COALESCE(tss.total_store_sales, 0) > COALESCE(tcs.total_catalog_sales, 0) THEN 'Store Dominant'
        ELSE 'Equal Sales'
    END AS Sales_Dominance,
    CASE 
        WHEN COUNT(DISTINCT id.income_rank) > 3 THEN 'High Income Diversity'
        WHEN COUNT(DISTINCT id.income_rank) = 1 THEN 'Single Income Band'
        ELSE 'Moderate Income Diversity'
    END AS Income_Diversity
FROM customer c
LEFT JOIN AggregatedSales tws ON c.c_customer_sk = tws.c_customer_sk
LEFT JOIN AggregatedSales tcs ON c.c_customer_sk = tcs.c_customer_sk
LEFT JOIN AggregatedSales tss ON c.c_customer_sk = tss.c_customer_sk
LEFT JOIN IncomeDemographics id ON c.c_current_cdemo_sk = id.hd_demo_sk
GROUP BY c.c_customer_id, tws.total_web_sales, tcs.total_catalog_sales, tss.total_store_sales
ORDER BY c.c_customer_id;
