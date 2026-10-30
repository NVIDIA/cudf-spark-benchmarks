
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city AS customer_city,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_sales_price) AS total_spent,
    MAX(ws.ws_sold_date_sk) AS last_purchase_date,
    SUBSTR(ca.ca_street_name, 1, 5) AS street_excerpt,
    REPLACE(LOWER(c.c_email_address), '@', ' [at] ') AS formatted_email
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, street_excerpt, formatted_email
HAVING 
    COUNT(DISTINCT ws.ws_order_number) >= 5 
ORDER BY 
    total_spent DESC 
LIMIT 10;
