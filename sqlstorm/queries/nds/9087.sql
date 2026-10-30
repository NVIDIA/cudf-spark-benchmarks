
WITH sales_data AS (
    SELECT 
        d.d_year,
        c.c_customer_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2023
    GROUP BY 
        d.d_year, c.c_customer_id
),
top_customers AS (
    SELECT 
        d_year,
        c_customer_id,
        total_sales,
        order_count,
        avg_order_value,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
),
high_value_customers AS (
    SELECT 
        d_year,
        c_customer_id,
        total_sales,
        order_count,
        avg_order_value
    FROM 
        top_customers
    WHERE 
        sales_rank <= 10
)
SELECT 
    hvc.d_year,
    COUNT(hvc.c_customer_id) AS high_value_customer_count,
    SUM(hvc.total_sales) AS total_high_value_sales,
    AVG(hvc.avg_order_value) AS avg_high_value_order_value
FROM 
    high_value_customers hvc
GROUP BY 
    hvc.d_year
ORDER BY 
    hvc.d_year;
