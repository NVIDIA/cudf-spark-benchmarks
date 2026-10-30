
SELECT 
    ca_city,
    COUNT(DISTINCT c_customer_sk) AS customer_count,
    SUM(ws_ext_sales_price) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    ca_state = 'CA'
    AND ws.ws_sold_date_sk BETWEEN 1 AND 10000
GROUP BY 
    ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
