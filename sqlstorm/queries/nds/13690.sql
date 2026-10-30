
SELECT 
    d.d_year, 
    SUM(ws.ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers 
FROM 
    web_sales ws 
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
WHERE 
    d.d_year BETWEEN 2021 AND 2023 
GROUP BY 
    d.d_year 
ORDER BY 
    d.d_year;
