
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    s.ss_sales_price, 
    s.ss_quantity 
FROM 
    customer c 
JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk 
WHERE 
    s.ss_sold_date_sk = 20230101 
ORDER BY 
    s.ss_sales_price DESC 
LIMIT 10;
