
WITH  customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
customer_demo_with_sales AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cs.total_sales,
        cs.order_count
    FROM customer_demographics cd
    LEFT JOIN customer_sales cs ON cd.cd_demo_sk = cs.c_customer_sk
),
top_customers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.total_sales,
        cd.order_count,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.total_sales DESC) AS gender_rank
    FROM customer_demo_with_sales cd
    WHERE cd.total_sales IS NOT NULL
)
SELECT 
    c.c_customer_id,
    cd.cd_gender AS gender,
    COALESCE(cd.total_sales, 0) AS total_sales,
    COALESCE(cd.order_count, 0) AS order_count,
    d.d_date AS sales_date,
    d.d_week_seq AS week_number,
    CASE 
        WHEN cd.cd_gender = 'M' AND cd.order_count > 5 THEN 'Frequent Male Buyer'
        WHEN cd.cd_gender = 'F' AND cd.order_count > 5 THEN 'Frequent Female Buyer'
        ELSE 'Occasional Buyer'
    END AS buyer_type
FROM customer c
LEFT JOIN top_customers cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
CROSS JOIN date_dim d
WHERE d.d_date BETWEEN DATE '2002-10-01' - INTERVAL '30 DAY' AND DATE '2002-10-01'
AND NOT EXISTS (
    SELECT 1 
    FROM store_sales ss 
    WHERE ss.ss_customer_sk = c.c_customer_sk
    AND ss.ss_sold_date_sk = d.d_date_sk
)
ORDER BY total_sales DESC, week_number;
