SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) > 10000 THEN 'High Value Customer'
        WHEN SUM(ws.ws_ext_sales_price) BETWEEN 5000 AND 10000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_segment
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2001
    AND d.d_moy IN (6, 7, 8)  
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    SUM(ws.ws_ext_sales_price) > 0
ORDER BY 
    total_sales DESC
LIMIT 100;