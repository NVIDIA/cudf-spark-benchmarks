
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    MAX(ws.ws_sold_date_sk) AS last_order_date,
    MIN(ws.ws_sold_date_sk) AS first_order_date,
    CASE 
        WHEN AVG(ws.ws_ext_sales_price) > 50 THEN 'High Value Customer'
        WHEN AVG(ws.ws_ext_sales_price) BETWEEN 20 AND 50 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5 
ORDER BY 
    total_sales DESC
LIMIT 10;
