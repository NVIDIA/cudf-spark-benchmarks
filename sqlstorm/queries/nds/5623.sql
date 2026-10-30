
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        cs.total_sales,
        cs.number_of_orders,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) as rn
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
),
sales_by_state AS (
    SELECT 
        ca.ca_state,
        SUM(ws.ws_net_paid) AS total_sales_by_state,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_by_state
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ca.ca_state
)
SELECT 
    tc.c_customer_id,
    tc.total_sales,
    tc.number_of_orders,
    sb.total_sales_by_state,
    sb.total_orders_by_state
FROM 
    top_customers tc
JOIN 
    sales_by_state sb ON sb.total_sales_by_state > 10000
WHERE 
    tc.rn <= 10
ORDER BY 
    tc.total_sales DESC;
