
SELECT 
    c.c_customer_id,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_sales_price) AS total_sales_price,
    AVG(ss.ss_net_profit) AS average_net_profit,
    d.d_year
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_id, d.d_year
ORDER BY 
    d.d_year, total_sales_price DESC
LIMIT 100;
