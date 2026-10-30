
WITH sales_summary AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c_customer_id AS customer_id,
        c_first_name,
        c_last_name,
        total_sales,
        total_profit,
        order_count,
        last_purchase_date
    FROM 
        sales_summary
    WHERE 
        total_sales > 1000
    ORDER BY 
        total_sales DESC
    LIMIT 10
)
SELECT 
    tc.customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_profit,
    tc.order_count,
    tc.last_purchase_date,
    a.ca_city,
    a.ca_state
FROM 
    top_customers tc
JOIN 
    customer_address a ON tc.customer_id = a.ca_address_id
WHERE 
    a.ca_state IN ('CA', 'TX', 'NY')
ORDER BY 
    tc.total_profit DESC;
