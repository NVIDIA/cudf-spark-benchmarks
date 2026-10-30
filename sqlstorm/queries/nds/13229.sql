
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_quantity) AS average_quantity_sold,
    MIN(ss.ss_sold_date_sk) AS first_sale_date,
    MAX(ss.ss_sold_date_sk) AS last_sale_date
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_month_seq
ORDER BY 
    d.d_month_seq;
