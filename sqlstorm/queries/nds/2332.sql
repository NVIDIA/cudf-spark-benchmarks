
WITH sales_summary AS (
    SELECT 
        coalesce(ws_bill_customer_sk, ss_customer_sk) AS customer_sk,
        coalesce(ws_ship_customer_sk, ss_customer_sk) AS ship_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(COALESCE(ws_net_profit, ss_net_profit, 0)) AS total_profit,
        SUM(COALESCE(ws_net_paid_inc_tax, ss_net_paid_inc_tax, 0)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY coalesce(ws_bill_customer_sk, ss_customer_sk) ORDER BY SUM(COALESCE(ws_net_profit, ss_net_profit, 0)) DESC) AS rn
    FROM 
        web_sales ws
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    GROUP BY 
        coalesce(ws_bill_customer_sk, ss_customer_sk), coalesce(ws_ship_customer_sk, ss_customer_sk)
),

top_customers AS (
    SELECT customer_sk, total_orders, total_profit, total_revenue
    FROM sales_summary
    WHERE rn <= 10
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    tc.total_orders,
    tc.total_profit,
    tc.total_revenue
FROM 
    top_customers tc
INNER JOIN customer c ON tc.customer_sk = c.c_customer_sk
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    tc.total_revenue > 10000
ORDER BY 
    tc.total_profit DESC;
