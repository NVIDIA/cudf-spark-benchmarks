
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        s.total_net_profit,
        s.total_orders,
        s.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY s.total_net_profit DESC) AS rank
    FROM 
        sales_summary s
    JOIN 
        customer c ON s.c_customer_id = c.c_customer_id
)
SELECT 
    tc.customer_id,
    tc.total_net_profit,
    tc.total_orders,
    tc.avg_order_value
FROM 
    top_customers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC;
