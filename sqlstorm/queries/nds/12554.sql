
SELECT 
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(cs.cs_order_number) AS total_orders
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
WHERE 
    ca.ca_city = 'Los Angeles'
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450600
GROUP BY 
    c.c_customer_id, ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 100;
