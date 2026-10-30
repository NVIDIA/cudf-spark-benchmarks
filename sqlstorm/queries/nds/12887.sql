
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(s.ws_sales_price) AS total_sales 
FROM 
    customer c 
JOIN 
    web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk 
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990 
GROUP BY 
    c.c_customer_sk, c.c_first_name, c.c_last_name 
ORDER BY 
    total_sales DESC 
LIMIT 100;
