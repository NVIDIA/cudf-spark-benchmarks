
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(ws.ws_order_number) AS order_count,
    MAX(d.d_date) AS last_purchase_date
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 10;
