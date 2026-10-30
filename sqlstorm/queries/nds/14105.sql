
SELECT 
    c.c_customer_id, 
    COUNT(ss.ss_ticket_number) AS total_sales, 
    SUM(ss.ss_net_paid) AS total_revenue, 
    AVG(ss.ss_net_paid) AS avg_sales_per_order 
FROM 
    customer AS c 
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk 
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
GROUP BY 
    c.c_customer_id 
ORDER BY 
    total_revenue DESC 
LIMIT 100;
