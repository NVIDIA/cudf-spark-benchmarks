
WITH customer_sales AS (
    SELECT 
        c.c_customer_id AS customer_id,
        c.c_first_name AS first_name,
        c.c_last_name AS last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(d.d_date) AS last_purchase_date
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
        c.customer_id,
        c.first_name,
        c.last_name,
        c.total_sales,
        c.total_orders,
        c.last_purchase_date,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        customer_sales c
)
SELECT 
    tc.customer_id,
    tc.first_name,
    tc.last_name,
    tc.total_sales,
    tc.total_orders,
    tc.last_purchase_date
FROM 
    top_customers tc
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
