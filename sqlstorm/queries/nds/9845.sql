
WITH customer_sales_data AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        csd.c_customer_id,
        csd.total_spent,
        csd.total_orders,
        RANK() OVER (ORDER BY csd.total_spent DESC) AS customer_rank
    FROM 
        customer_sales_data csd
    WHERE 
        csd.total_orders > 5
),
sales_by_day AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_net_paid) AS daily_sales
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        dd.d_date
)
SELECT 
    tc.c_customer_id,
    tc.total_spent,
    tc.total_orders,
    sd.d_date,
    sd.daily_sales
FROM 
    top_customers tc
JOIN 
    sales_by_day sd ON tc.total_orders = (SELECT MAX(total_orders) FROM top_customers)
ORDER BY 
    tc.total_spent DESC, sd.d_date;
