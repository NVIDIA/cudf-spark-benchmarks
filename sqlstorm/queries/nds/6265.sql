
WITH sales_data AS (
    SELECT 
        d.d_year,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_orders
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, c.c_first_name, c.c_last_name
),
top_sales AS (
    SELECT 
        d_year,
        c_first_name,
        c_last_name,
        total_sales,
        number_of_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_data
)
SELECT 
    d_year,
    c_first_name,
    c_last_name,
    total_sales,
    number_of_orders
FROM 
    top_sales
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, sales_rank;
