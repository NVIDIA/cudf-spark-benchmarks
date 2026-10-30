
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), state_sales AS (
    SELECT 
        ca.ca_state,
        SUM(cs.total_sales) AS state_sales_total,
        COUNT(cs.c_customer_id) AS total_customers,
        AVG(cs.average_profit) AS avg_profit_per_customer
    FROM 
        customer_sales cs
    JOIN 
        customer_address ca ON cs.c_customer_id = ca.ca_address_id
    GROUP BY 
        ca.ca_state
)
SELECT 
    ss.ca_state,
    ss.state_sales_total,
    ss.total_customers,
    ss.avg_profit_per_customer,
    ROW_NUMBER() OVER (ORDER BY ss.state_sales_total DESC) AS sales_rank
FROM 
    state_sales ss
WHERE 
    ss.total_customers > 100
ORDER BY 
    ss.state_sales_total DESC
LIMIT 10;
