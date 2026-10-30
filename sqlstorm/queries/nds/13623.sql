
SELECT 
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ss.ss_sales_price) AS total_sales,
    AVG(ss.ss_net_profit) AS average_net_profit,
    d.d_year AS sales_year
FROM 
    store_sales ss
JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
GROUP BY 
    d.d_year
ORDER BY 
    sales_year DESC;
