
SELECT 
    c.c_customer_id,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_sales_price) AS total_sales,
    d.d_year
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2020 AND 2023
GROUP BY 
    c.c_customer_id, d.d_year
ORDER BY 
    total_sales DESC
LIMIT 100;
