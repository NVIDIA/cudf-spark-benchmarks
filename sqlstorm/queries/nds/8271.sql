
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_date = '2023-01-01'
        ) AND (
            SELECT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_date = '2023-12-31'
        )
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        cs.c_customer_id, 
        cs.total_sales, 
        cs.total_orders, 
        cs.avg_net_profit,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
),
customer_addresses AS (
    SELECT 
        tc.c_customer_id,
        a.ca_city,
        a.ca_state,
        a.ca_country,
        RANK() OVER (PARTITION BY tc.c_customer_id ORDER BY a.ca_city) AS city_rank
    FROM 
        top_customers tc
    JOIN 
        customer_address a ON tc.c_customer_id = a.ca_address_id
)
SELECT 
    t.c_customer_id,
    t.total_sales,
    t.total_orders,
    t.avg_net_profit,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    top_customers t
JOIN 
    customer_addresses ca ON t.c_customer_id = ca.c_customer_id
WHERE 
    t.sales_rank <= 10 AND ca.city_rank = 1
ORDER BY 
    t.total_sales DESC;
