
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, ca.ca_city
    HAVING AVG(ws.ws_net_profit) > 100 AND SUM(ws.ws_ext_sales_price) > 1000
),
sales_trends AS (
    SELECT 
        dt.d_year,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM date_dim dt
    JOIN web_sales ws ON dt.d_date_sk = ws.ws_sold_date_sk
    GROUP BY dt.d_year
)
SELECT 
    cs.c_first_name AS first_name,
    cs.c_last_name AS last_name,
    hvc.ca_city,
    COALESCE(hvc.total_spent, 0) AS total_spent,
    COALESCE(hvc.avg_net_profit, 0) AS avg_net_profit,
    st.total_quantity_sold,
    st.total_net_profit
FROM customer_sales cs
LEFT JOIN high_value_customers hvc ON cs.c_customer_sk = hvc.c_customer_sk
JOIN sales_trends st ON st.d_year = EXTRACT(YEAR FROM DATE '2002-10-01')
WHERE cs.rnk <= 10
ORDER BY cs.total_net_profit DESC;
