
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_sales_price) AS total_sales,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS order_count
FROM 
    customer AS c
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    d.d_year = 2022 
    AND c.c_preferred_cust_flag = 'Y'
    AND ca.ca_state IN ('CA', 'TX', 'NY')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    d.d_year, 
    d.d_month_seq, 
    ca.ca_city, 
    ca.ca_state
HAVING 
    SUM(ws.ws_quantity) > 100
ORDER BY 
    total_sales DESC, 
    total_quantity DESC
LIMIT 50;
