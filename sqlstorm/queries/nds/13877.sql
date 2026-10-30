
SELECT 
    c.c_customer_id,
    ca.ca_city,
    COUNT(DISTINCT w.w_warehouse_id) AS warehouse_count,
    SUM(ss.ss_sales_price) AS total_sales
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store s ON c.c_customer_sk = s.s_store_sk
JOIN 
    store_sales ss ON ss.ss_store_sk = s.s_store_sk
JOIN 
    warehouse w ON s.s_store_sk = w.w_warehouse_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 100;
