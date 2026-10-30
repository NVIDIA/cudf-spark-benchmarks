
SELECT 
    CONCAT(COALESCE(c.c_salutation, ''), ' ', c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    REPLACE(REPLACE(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type), ' Street', ''), ' Avenue', '') AS formatted_address,
    d.d_date AS purchase_date,
    EXTRACT(YEAR FROM d.d_date) AS purchase_year,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_profit) AS total_net_profit
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
AND 
    c.c_birth_country LIKE '%United States%'
GROUP BY 
    CONCAT(COALESCE(c.c_salutation, ''), ' ', c.c_first_name, ' ', c.c_last_name), 
    REPLACE(REPLACE(CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type), ' Street', ''), ' Avenue', ''),
    d.d_date,
    EXTRACT(YEAR FROM d.d_date)
ORDER BY 
    total_net_profit DESC
LIMIT 100;
