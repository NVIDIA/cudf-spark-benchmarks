
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
    COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
WHERE 
    ca.ca_city LIKE '%ville%' 
    AND ca.ca_state IN ('CA', 'NY') 
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC
LIMIT 100;
