
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, d.d_date
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(cd.total_sales) AS total_sales_per_customer,
        COUNT(cd.order_count) AS total_orders_per_customer,
        AVG(cd.avg_net_profit) AS avg_profit_per_customer
    FROM 
        customer_data cd
    JOIN 
        customer c ON cd.c_customer_id = c.c_customer_id
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_sales_per_customer DESC
    LIMIT 10
)
SELECT 
    tc.c_customer_id,
    tc.total_sales_per_customer,
    tc.total_orders_per_customer,
    tc.avg_profit_per_customer,
    ca.ca_city,
    ca.ca_state
FROM 
    top_customers tc
JOIN 
    customer c ON tc.c_customer_id = c.c_customer_id
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_country = 'USA';
