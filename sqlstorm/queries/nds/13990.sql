
SELECT 
    c.c_customer_id,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(d.d_date) AS last_purchase_date
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    c.c_customer_id
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY 
    total_sales DESC;
