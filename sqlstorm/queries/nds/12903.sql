
SELECT 
    d.d_year, 
    COUNT(DISTINCT c.c_customer_id) AS total_customers, 
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    date_dim d
JOIN 
    web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
