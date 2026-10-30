
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_quantity) AS total_items_sold,
    SUM(ss.ss_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY', 'TX')
    AND c.c_preferred_cust_flag = 'Y'
    AND c.c_birth_year BETWEEN 1980 AND 1990
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state
HAVING 
    SUM(ss.ss_sales_price) > 1000
ORDER BY 
    total_sales DESC
LIMIT 100;
