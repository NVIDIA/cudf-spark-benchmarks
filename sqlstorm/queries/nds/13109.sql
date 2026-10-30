
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    sum(ws.ws_quantity) as total_quantity, 
    sum(ws.ws_sales_price) as total_sales 
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
WHERE 
    ca.ca_state = 'CA' 
    AND ws.ws_sold_date_sk BETWEEN 2458438 AND 2458490 
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city 
ORDER BY 
    total_sales DESC 
LIMIT 100;
