
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS average_net_profit,
    d.d_year AS sales_year
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
