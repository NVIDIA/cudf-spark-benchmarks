
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(ws_sales_price) AS total_sales
FROM 
    customer_address 
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk
WHERE 
    ca_state = 'CA' 
    AND ws_sold_date_sk BETWEEN 1 AND 365
GROUP BY 
    ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
