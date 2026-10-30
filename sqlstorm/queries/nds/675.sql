WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS average_order_value
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.total_orders,
        cs.average_order_value,
        DENSE_RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM customer_sales cs
),
customer_details AS (
    SELECT 
        tc.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM top_customers tc
    LEFT JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
)
SELECT 
    cu.c_customer_id,
    COALESCE(cd.cd_gender, 'Unknown') AS gender,
    COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
    cd.cd_purchase_estimate,
    cu_sales.total_sales,
    cu_sales.total_orders,
    cu_sales.average_order_value,
    CASE 
        WHEN cu_sales.total_sales IS NULL THEN 0 
        ELSE cu_sales.total_sales 
    END AS sales_not_null
FROM customer cu
LEFT JOIN customer_details cd ON cu.c_customer_sk = cd.c_customer_sk
LEFT JOIN (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_ext_sales_price) AS average_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
) AS cu_sales ON cu.c_customer_sk = cu_sales.c_customer_sk
ORDER BY sales_not_null DESC
LIMIT 100;