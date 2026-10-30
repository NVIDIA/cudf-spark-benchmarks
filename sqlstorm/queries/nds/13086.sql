
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_sales_price) AS average_sales,
    MAX(ss.ss_sales_price) AS max_sales,
    MIN(ss.ss_sales_price) AS min_sales
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_month_seq
ORDER BY 
    d.d_month_seq;
