
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    SUM(s.ws_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
JOIN 
    date_dim d ON s.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_first_name, c.c_last_name, d.d_date
ORDER BY 
    total_sales DESC
LIMIT 10;
