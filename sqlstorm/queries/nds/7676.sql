
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    COALESCE(cs.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(cs.total_store_sales, 0) AS total_store_sales,
    (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS total_sales,
    COUNT(DISTINCT cs.c_customer_sk) AS customer_count
FROM 
    CustomerSales cs
JOIN Demographics d ON cs.c_customer_sk = d.cd_demo_sk
JOIN income_band ib ON d.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    ib.ib_lower_bound IS NOT NULL AND 
    (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) > 0
GROUP BY 
    d.cd_gender,
    d.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales
ORDER BY 
    total_sales DESC
LIMIT 100;
