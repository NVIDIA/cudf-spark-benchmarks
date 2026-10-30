
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS total_customers,
    SUM(ws_quantity) AS total_quantity_sold,
    AVG(ws_net_paid) AS average_order_value,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_customers,
    MIN(d_date) AS first_sale_date,
    MAX(d_date) AS last_sale_date
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    ca_state
ORDER BY 
    total_quantity_sold DESC
LIMIT 10;
