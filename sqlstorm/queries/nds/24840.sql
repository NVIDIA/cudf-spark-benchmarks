
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COUNT(DISTINCT c.c_first_shipto_date_sk) AS distinct_ship_dates
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
income_distribution AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN hd.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN hd.hd_income_band_sk = 1 THEN 'Low'
            WHEN hd.hd_income_band_sk BETWEEN 2 AND 5 THEN 'Medium'
            ELSE 'High'
        END AS income_band,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_profit
    FROM 
        household_demographics hd
    LEFT JOIN 
        customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON ss.ss_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, hd.hd_income_band_sk
),
customer_ranked AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
)
SELECT 
    cr.c_customer_id,
    cr.total_web_sales,
    cr.total_catalog_sales,
    cr.total_store_sales,
    id.income_band,
    id.total_profit,
    CASE 
        WHEN cr.sales_rank <= 10 AND id.total_profit IS NOT NULL THEN 'VIP Customer'
        WHEN cr.sales_rank BETWEEN 11 AND 50 THEN 'Valued Customer'
        ELSE 'Regular Customer'
    END AS customer_category,
    COALESCE(cr.total_web_sales, 0) - COALESCE(cr.total_catalog_sales, 0) AS web_minus_catalog,
    (SELECT AVG(total_web_sales) 
     FROM customer_sales 
     WHERE total_web_sales > 0) AS avg_positive_web_sales
FROM 
    customer_ranked cr
JOIN 
    income_distribution id ON cr.c_customer_sk = id.cd_demo_sk
WHERE 
    cr.total_store_sales > (SELECT AVG(total_store_sales) FROM customer_sales)
ORDER BY 
    cr.sales_rank
LIMIT 100;
