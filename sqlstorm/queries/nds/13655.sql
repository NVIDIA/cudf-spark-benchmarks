
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT o.ws_order_number) AS total_orders,
    SUM(o.ws_ext_sales_price) AS total_sales,
    AVG(o.ws_ext_sales_price) AS avg_sales,
    MAX(o.ws_ext_sales_price) AS max_sales,
    MIN(o.ws_ext_sales_price) AS min_sales
FROM 
    customer c
JOIN 
    web_sales o ON c.c_customer_sk = o.ws_bill_customer_sk
JOIN 
    date_dim d ON o.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
