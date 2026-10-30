
SELECT 
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    w.w_warehouse_name,
    sum(ss.ss_sales_price) AS total_sales,
    count(ss.ss_ticket_number) AS total_transactions
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    store s ON ss.ss_store_sk = s.s_store_sk
JOIN 
    warehouse w ON s.s_company_id = w.w_warehouse_sk
WHERE 
    ca.ca_city = 'San Francisco'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, w.w_warehouse_name
ORDER BY 
    total_sales DESC
LIMIT 10;
