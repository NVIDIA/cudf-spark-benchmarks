
SELECT 
    c_first_name, 
    c_last_name, 
    ca_city, 
    SUM(ws_net_paid) AS total_spent
FROM 
    customer 
JOIN 
    customer_address ON c_current_addr_sk = ca_address_sk 
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk 
GROUP BY 
    c_first_name, c_last_name, ca_city
ORDER BY 
    total_spent DESC
LIMIT 10;
