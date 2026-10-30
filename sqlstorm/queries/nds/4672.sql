
WITH  item_sales AS (
    SELECT 
        i.i_item_id,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(ws.ws_sales_price), 0) DESC) AS sales_rank
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_id
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
top_customers AS (
    SELECT 
        cs.c_customer_id,
        cs.order_count,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM customer_sales cs
)
SELECT 
    isc.i_item_id,
    isc.total_sales,
    isc.total_quantity,
    tc.c_customer_id,
    tc.order_count,
    tc.total_spent,
    CASE 
        WHEN tc.order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Placed'
    END AS order_status
FROM item_sales isc
FULL OUTER JOIN top_customers tc ON isc.sales_rank = tc.customer_rank
WHERE (tc.order_count > 10 OR isc.total_sales > 50000)
  AND (tc.total_spent IS NULL OR tc.total_spent BETWEEN 1000 AND 5000)
ORDER BY isc.total_sales DESC, tc.total_spent DESC;
