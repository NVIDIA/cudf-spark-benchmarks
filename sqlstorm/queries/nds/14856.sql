
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_sales_price) AS average_sales_price,
    d.d_year AS sales_year
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    d.d_year
ORDER BY 
    sales_year;
