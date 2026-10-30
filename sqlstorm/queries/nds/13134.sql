
SELECT 
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ss_sales_price) AS total_sales,
    AVG(ss_quantity) AS average_quantity,
    d_year
FROM 
    store_sales ss
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
GROUP BY 
    d_year
ORDER BY 
    d_year DESC
LIMIT 10;
