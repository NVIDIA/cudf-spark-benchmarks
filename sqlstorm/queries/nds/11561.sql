
SELECT 
    c.c_current_addr_sk, 
    COUNT(DISTINCT ws.ws_order_number) AS total_orders, 
    SUM(ws.ws_net_paid_inc_tax) AS total_revenue 
FROM 
    customer c 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
WHERE 
    d.d_year = 2023 
GROUP BY 
    c.c_current_addr_sk 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
