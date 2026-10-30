
SELECT 
    c.c_customer_id,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    AVG(ws.ws_sales_price) AS average_order_value,
    d.d_year
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2022 AND 2023
GROUP BY 
    c.c_customer_id, d.d_year
ORDER BY 
    total_sales DESC
LIMIT 100;
