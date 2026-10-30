
WITH customer_order_data AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        d.d_year,
        d.d_month_seq
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        c.c_customer_id, d.d_year, d.d_month_seq
),
monthly_sales AS (
    SELECT 
        c_year,
        c_month,
        SUM(total_sales) AS monthly_sales_total,
        COUNT(DISTINCT c_customer_id) AS unique_customers
    FROM (
        SELECT 
            d_year AS c_year,
            d_month_seq AS c_month,
            customer_order_data.total_sales,
            customer_order_data.c_customer_id
        FROM 
            customer_order_data
    ) AS monthly_data
    GROUP BY 
        c_year, c_month
)
SELECT 
    c_year,
    c_month,
    monthly_sales_total,
    unique_customers,
    (monthly_sales_total / NULLIF(unique_customers, 0)) AS avg_spent_per_customer
FROM 
    monthly_sales
ORDER BY 
    c_year, c_month;
