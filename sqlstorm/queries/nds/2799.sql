
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(cs.cs_net_paid_inc_tax) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY c.c_customer_id
),
customer_demo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
combined_sales AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.web_order_count + cs.catalog_order_count AS total_orders
    FROM customer_sales cs
    JOIN customer_demo cd ON cs.c_customer_id = cd.c_customer_id
),
ranked_sales AS (
    SELECT 
        full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        total_web_sales,
        total_catalog_sales,
        total_orders,
        RANK() OVER (PARTITION BY cd_gender ORDER BY total_web_sales DESC) AS gender_rank
    FROM combined_sales
)
SELECT 
    r.full_name,
    r.cd_gender,
    r.cd_marital_status,
    r.cd_education_status,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_orders,
    CASE 
        WHEN r.total_web_sales IS NULL THEN 'No Web Sales'
        ELSE 'Web Sales Present'
    END AS sales_presence,
    COALESCE(r.total_web_sales, 0) + COALESCE(r.total_catalog_sales, 0) AS total_sales
FROM ranked_sales r
WHERE r.gender_rank <= 5
ORDER BY r.cd_gender, r.total_web_sales DESC;
