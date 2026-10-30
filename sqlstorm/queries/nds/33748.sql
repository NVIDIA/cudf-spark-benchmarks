
WITH  top_customers AS (
    SELECT 
        c_customer_sk, 
        COUNT(ws_order_number) AS order_count,
        SUM(ws_net_paid) AS total_spent
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c_customer_sk
    HAVING SUM(ws_net_paid) IS NOT NULL
),
customer_rank AS (
    SELECT 
        c.c_customer_id,
        tc.order_count,
        tc.total_spent,
        RANK() OVER (ORDER BY tc.total_spent DESC) AS customer_rank
    FROM top_customers tc
    JOIN customer c ON tc.c_customer_sk = c.c_customer_sk
),
total_sales AS (
    SELECT 
        SUM(ws_net_paid) AS total_sales_value,
        SUM(ws_ext_tax) AS total_tax,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
),
item_return_stats AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(*) AS return_count,
        SUM(wr_return_amt) AS total_returned
    FROM web_returns wr
    GROUP BY wr.wr_item_sk
),
items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(irs.return_count, 0) AS return_count,
        COALESCE(irs.total_returned, 0) AS total_returned
    FROM item i
    LEFT JOIN item_return_stats irs ON i.i_item_sk = irs.wr_item_sk
)
SELECT 
    cr.c_customer_id,
    cr.order_count,
    cr.total_spent,
    ts.total_sales_value,
    ts.total_orders,
    i.i_item_id,
    i.i_product_name,
    i.return_count,
    i.total_returned,
    CASE 
        WHEN i.return_count > 0 THEN 'High Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM customer_rank cr
CROSS JOIN total_sales ts
JOIN items i ON i.return_count > 0
WHERE cr.customer_rank <= 10
ORDER BY cr.total_spent DESC, i.total_returned DESC;
