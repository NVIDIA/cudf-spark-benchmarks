
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS sales_rank
    FROM web_sales
    WHERE ws_order_number IN (
        SELECT DISTINCT cr_order_number 
        FROM catalog_returns 
        WHERE cr_return_quantity > 0
    ) OR ws_order_number IN (
        SELECT DISTINCT wr_order_number 
        FROM web_returns 
        WHERE wr_return_quantity > 0
    )
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_sales_price) AS total_revenue
    FROM ranked_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
top_items AS (
    SELECT 
        i_item_id,
        total_orders,
        avg_sales_price,
        total_revenue,
        CASE 
            WHEN total_revenue IS NULL THEN 'No Revenue'
            WHEN total_revenue > 10000 THEN 'High Revenue'
            ELSE 'Low Revenue' 
        END AS revenue_category
    FROM item_summary
    WHERE total_orders >= 5 
    ORDER BY total_revenue DESC
    LIMIT 10
)
SELECT 
    ti.i_item_id,
    COALESCE(ti.total_orders, 0) AS total_orders,
    COALESCE(ti.avg_sales_price, 0) AS avg_sales_price,
    COALESCE(ti.total_revenue, 0) AS total_revenue,
    ti.revenue_category,
    da.ca_city,
    da.ca_state
FROM top_items ti
LEFT JOIN customer_address da ON LENGTH(da.ca_zip) = (SELECT MAX(LENGTH(ca_zip)) FROM customer_address)
WHERE ti.total_revenue IS NOT NULL
UNION ALL
SELECT 
    NULL,
    NULL,
    NULL,
    NULL,
    'Null Category' AS revenue_category,
    'Unknown City' AS ca_city,
    'Unknown State' AS ca_state
WHERE NOT EXISTS (
    SELECT 1 
    FROM top_items
)
ORDER BY revenue_category, total_revenue DESC;
