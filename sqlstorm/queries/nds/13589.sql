
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales, 
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    s.s_store_name, 
    d.d_year
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store AS s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, s.s_store_name, d.d_year
ORDER BY 
    total_sales DESC
LIMIT 1000;
