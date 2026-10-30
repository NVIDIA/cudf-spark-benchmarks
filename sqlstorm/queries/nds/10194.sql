
SELECT 
    c.c_first_name,
    c.c_last_name,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_sales_price) AS total_sales_price,
    MAX(ss.ss_sold_date_sk) AS last_purchase_date
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    c.c_first_name, c.c_last_name
ORDER BY 
    total_sales_price DESC
LIMIT 100;
