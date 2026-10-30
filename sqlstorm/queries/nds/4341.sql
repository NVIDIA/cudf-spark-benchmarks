
WITH CTE_CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_SalesByIncomeBand AS (
    SELECT 
        CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN 
                hd.hd_income_band_sk 
            ELSE 
                -1 
        END AS income_band,
        SUM(c.total_web_sales) AS total_web_sales_income_band,
        SUM(c.total_catalog_sales) AS total_catalog_sales_income_band,
        SUM(c.total_store_sales) AS total_store_sales_income_band
    FROM CTE_CustomerSales c
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk
),
CTE_RankedSales AS (
    SELECT 
        income_band,
        total_web_sales_income_band,
        total_catalog_sales_income_band,
        total_store_sales_income_band,
        RANK() OVER (ORDER BY total_web_sales_income_band DESC) AS sales_rank
    FROM CTE_SalesByIncomeBand
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(r.total_web_sales_income_band, 0) AS total_web_sales,
    COALESCE(r.total_catalog_sales_income_band, 0) AS total_catalog_sales,
    COALESCE(r.total_store_sales_income_band, 0) AS total_store_sales
FROM income_band ib
FULL OUTER JOIN CTE_RankedSales r ON ib.ib_income_band_sk = r.income_band
WHERE 
    (r.sales_rank <= 10 OR r.sales_rank IS NULL)
    AND (COALESCE(r.total_web_sales_income_band, 0) > 5000 
         OR COALESCE(r.total_catalog_sales_income_band, 0) > 3000 
         OR COALESCE(r.total_store_sales_income_band, 0) > 7000)
ORDER BY ib.ib_lower_bound;
