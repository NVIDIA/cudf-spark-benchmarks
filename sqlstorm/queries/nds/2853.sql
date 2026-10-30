
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) +
        COALESCE(SUM(cs.cs_ext_sales_price), 0) +
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
ranked_sales AS (
    SELECT 
        c_customer_id,
        total_sales,
        web_order_count,
        catalog_order_count,
        store_order_count,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM customer_sales
),
customer_demographics AS (
    SELECT 
        cd.cd_gender,
        COUNT(*) AS customer_count,
        AVG(total_sales) AS avg_sales,
        AVG(web_order_count) AS avg_web_orders,
        AVG(catalog_order_count) AS avg_catalog_orders,
        AVG(store_order_count) AS avg_store_orders
    FROM ranked_sales
    JOIN customer c ON ranked_sales.c_customer_id = c.c_customer_id
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    cd_gender,
    customer_count,
    ROUND(avg_sales, 2) AS avg_sales,
    ROUND(avg_web_orders, 2) AS avg_web_orders,
    ROUND(avg_catalog_orders, 2) AS avg_catalog_orders,
    ROUND(avg_store_orders, 2) AS avg_store_orders
FROM customer_demographics
WHERE customer_count > 0
ORDER BY avg_sales DESC
LIMIT 10;
