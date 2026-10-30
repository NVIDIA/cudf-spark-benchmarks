
SELECT 
    c.c_customer_id, 
    COUNT(ws.ws_order_number) AS total_web_sales,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax 
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
    total_web_sales DESC 
LIMIT 10;
