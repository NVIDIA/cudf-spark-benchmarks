
SELECT 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_sales_price) AS total_sales 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk 
WHERE 
    dd.d_year = 2023 
GROUP BY 
    c.c_customer_sk, 
    c.c_first_name, 
    c.c_last_name 
ORDER BY 
    total_sales DESC 
LIMIT 10;
