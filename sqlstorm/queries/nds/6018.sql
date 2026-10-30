
WITH sales_data AS (
    SELECT 
        d.d_year,
        c.c_birth_country,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2018 AND 2022
    GROUP BY 
        d.d_year, c.c_birth_country
),
top_countries AS (
    SELECT 
        c_birth_country, 
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS rn
    FROM 
        sales_data
)
SELECT 
    d.d_year,
    tc.c_birth_country,
    sd.total_sales,
    sd.order_count,
    sd.unique_customers
FROM 
    sales_data sd
JOIN 
    top_countries tc ON sd.c_birth_country = tc.c_birth_country
JOIN 
    date_dim d ON sd.d_year = d.d_year
WHERE 
    tc.rn <= 5
ORDER BY 
    d.d_year, total_sales DESC;
