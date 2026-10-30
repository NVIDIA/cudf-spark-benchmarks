
SELECT 
    CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_sales_price) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    ca_city LIKE 'New%' 
    AND ca_state = 'CA'
GROUP BY 
    full_address
ORDER BY 
    total_sales DESC
LIMIT 10;
