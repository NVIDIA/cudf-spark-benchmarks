
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_Household_Income AS (
    SELECT 
        hd.hd_demo_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
CTE_Top_Customers AS (
    SELECT 
        CTE.c_customer_sk,
        CTE.c_first_name,
        CTE.c_last_name,
        (CTE.total_web_sales + CTE.total_catalog_sales + CTE.total_store_sales) AS total_sales,
        RANK() OVER (ORDER BY (CTE.total_web_sales + CTE.total_catalog_sales + CTE.total_store_sales) DESC) AS sales_rank
    FROM CTE_Customer_Sales CTE
)
SELECT 
    T.c_first_name,
    T.c_last_name,
    T.total_sales,
    HI.ib_lower_bound,
    HI.ib_upper_bound
FROM CTE_Top_Customers T
JOIN CTE_Household_Income HI ON T.c_customer_sk = HI.hd_demo_sk
WHERE T.sales_rank <= 10
UNION ALL
SELECT 
    'Overall Total' AS c_first_name,
    NULL AS c_last_name,
    SUM(total_sales) AS total_sales,
    NULL AS ib_lower_bound,
    NULL AS ib_upper_bound
FROM CTE_Top_Customers
ORDER BY total_sales DESC;
