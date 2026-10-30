
WITH  sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_profit
    FROM web_sales
    GROUP BY ws_item_sk
    HAVING SUM(ws_net_profit) > 1000
), 
top_items AS (
    SELECT 
        i.i_item_id, 
        ss.total_quantity,
        ss.total_profit,
        ss.order_count,
        (SELECT COUNT(*) FROM web_sales WHERE ws_item_sk = i.i_item_sk) AS sell_count
    FROM item i
    JOIN sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    WHERE ss.rank_profit <= 10
),
customer_top AS (
    SELECT 
        c.c_customer_id,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
    HAVING SUM(ws.ws_net_paid_inc_tax) > 5000
)
SELECT 
    ct.c_customer_id,
    ti.i_item_id,
    ti.total_quantity,
    ti.total_profit,
    ti.order_count,
    ct.total_orders,
    ct.total_spent,
    COALESCE(CONCAT('Total orders: ', ct.total_orders), 'No Orders') AS order_summary
FROM top_items ti
LEFT JOIN customer_top ct ON ti.order_count = ct.total_orders
ORDER BY ti.total_profit DESC;
