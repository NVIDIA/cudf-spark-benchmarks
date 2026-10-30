
SELECT 
    c.c_customer_id,
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(ws_order_number) AS total_orders,
    MAX(d_year) AS last_year
FROM 
    web_sales
JOIN 
    customer c ON ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
