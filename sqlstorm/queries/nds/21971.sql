
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_spenders AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        ROW_NUMBER() OVER (ORDER BY (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) DESC) AS rn
    FROM customer_sales cs
),

average_sales AS (
    SELECT
        AVG(total) AS avg_sales
    FROM (
        SELECT 
            (total_web_sales + total_catalog_sales + total_store_sales) AS total
        FROM customer_sales
    ) AS total_sales
)

SELECT 
    hs.c_customer_sk,
    hs.c_first_name,
    hs.c_last_name,
    hs.total_web_sales,
    hs.total_catalog_sales,
    hs.total_store_sales,
    (CASE 
        WHEN (hs.total_web_sales + hs.total_catalog_sales + hs.total_store_sales) >= (SELECT avg_sales FROM average_sales)
        THEN 'Above Average'
        ELSE 'Below Average'
    END) AS sales_status,
    CASE 
        WHEN hs.rn <= 10 THEN 'Top 10 Spender'
        ELSE 'Regular Spender'
    END AS spender_category,
    (SELECT COUNT(*) FROM customer c2 WHERE c2.c_birth_year BETWEEN 1980 AND 1990) AS millennials_count
FROM high_spenders hs
WHERE hs.rn <= 50
ORDER BY (hs.total_web_sales + hs.total_catalog_sales + hs.total_store_sales) DESC
LIMIT 20;
