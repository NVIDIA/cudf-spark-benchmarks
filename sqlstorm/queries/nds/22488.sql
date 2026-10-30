
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws.ws_item_sk
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE cd.cd_purchase_estimate > 50000 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, cd.cd_gender
    HAVING SUM(ws.ws_sales_price) >= 1000
),
top_items_and_customers AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        h.c_customer_sk,
        h.order_count,
        h.total_spent,
        CASE 
            WHEN h.total_spent IS NULL THEN 'Lost Customer'
            WHEN h.total_spent > 5000 THEN 'VIP Customer'
            ELSE 'Regular Customer'
        END AS customer_status
    FROM ranked_sales r
    FULL OUTER JOIN high_value_customers h ON r.ws_item_sk = h.c_customer_sk
)
SELECT 
    ti.ws_item_sk,
    COALESCE(ti.total_sales, 0) AS total_sales_amount,
    COALESCE(ti.order_count, 0) AS total_orders,
    ti.customer_status,
    CASE 
        WHEN ti.customer_status = 'Lost Customer' AND COALESCE(ti.order_count, 0) = 0 THEN 'Contact for potential re-engagement'
        ELSE 'Stable Customer'
    END AS engagement_strategy
FROM top_items_and_customers ti
WHERE 
    ti.total_sales > (SELECT AVG(total_sales) FROM ranked_sales) 
    AND (ti.customer_status IS NOT NULL OR COALESCE(ti.order_count, 0) > 0)
ORDER BY ti.total_sales DESC, ti.order_count ASC
LIMIT 100 
OFFSET 0;
