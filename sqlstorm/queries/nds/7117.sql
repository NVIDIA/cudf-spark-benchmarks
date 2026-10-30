
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ws.ws_quantity) AS total_quantity_sold,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    d.d_year = 2023 
    AND d.d_month_seq BETWEEN 1 AND 6
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state
HAVING 
    SUM(ws.ws_net_paid_inc_tax) > 1000
ORDER BY 
    total_sales DESC;
