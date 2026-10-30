
WITH sales_summary AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
    GROUP BY 
        c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ss.total_quantity,
        ss.total_sales,
        ss.total_orders
    FROM 
        customer c
    JOIN 
        sales_summary ss ON c.c_first_name = ss.c_first_name AND c.c_last_name = ss.c_last_name
    WHERE 
        ss.total_sales > 5000
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.total_quantity,
    hvc.total_sales,
    hvc.total_orders,
    ROW_NUMBER() OVER (ORDER BY hvc.total_sales DESC) AS rank
FROM 
    high_value_customers hvc
ORDER BY 
    hvc.total_sales DESC
LIMIT 10;
