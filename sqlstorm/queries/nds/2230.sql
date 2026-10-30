
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
IncomeBandStats AS (
    SELECT 
        hd.hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(cs.total_web_sales) AS avg_web_sales,
        AVG(cs.total_catalog_sales) AS avg_catalog_sales,
        AVG(cs.total_store_sales) AS avg_store_sales
    FROM household_demographics hd
    LEFT JOIN CustomerSales cs ON hd.hd_demo_sk = cs.c_customer_sk
    GROUP BY hd.hd_income_band_sk
),
TopIncomeBands AS (
    SELECT 
        ib.ib_income_band_sk, 
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        RANK() OVER (ORDER BY AVG(ibs.avg_web_sales) DESC) AS income_rank
    FROM income_band ib
    JOIN IncomeBandStats ibs ON ib.ib_income_band_sk = ibs.hd_income_band_sk
    GROUP BY ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
)
SELECT 
    t.ib_income_band_sk,
    t.ib_lower_bound,
    t.ib_upper_bound,
    COALESCE(st.customer_count, 0) AS total_customers,
    COALESCE(st.avg_web_sales, 0) AS average_web_sales,
    COALESCE(st.avg_catalog_sales, 0) AS average_catalog_sales,
    COALESCE(st.avg_store_sales, 0) AS average_store_sales,
    CASE 
        WHEN t.income_rank <= 5 THEN 'Top 5 Income Bands'
        ELSE 'Other Income Bands' 
    END AS rank_group
FROM TopIncomeBands t
LEFT JOIN IncomeBandStats st ON t.ib_income_band_sk = st.hd_income_band_sk
WHERE t.ib_lower_bound IS NOT NULL OR t.ib_upper_bound IS NOT NULL
ORDER BY t.income_rank;
