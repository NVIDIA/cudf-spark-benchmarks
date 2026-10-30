
SELECT 
    c.c_customer_id,
    sum(ws.ws_sales_price) AS total_sales,
    count(distinct ws.ws_order_number) AS total_orders,
    avg(ws.ws_sales_price) AS avg_order_value,
    min(ws.ws_sales_price) AS min_order_value,
    max(ws.ws_sales_price) AS max_order_value
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id
ORDER BY 
    total_sales DESC
LIMIT 100;
