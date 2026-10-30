
SELECT 
    SUBSTRING(c.c_first_name, 1, 1) AS first_initial,
    UPPER(SUBSTRING(c.c_last_name, 1, 1)) AS last_initial,
    CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type) AS full_address,
    ca.ca_city,
    d.d_date AS transaction_date,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male' 
        WHEN cd.cd_gender = 'F' THEN 'Female' 
        ELSE 'Other' 
    END AS gender_description,
    COUNT(ws.ws_order_number) AS order_count,
    SUM(ws.ws_sales_price) AS total_spent
FROM 
    customer c 
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk 
GROUP BY 
    SUBSTRING(c.c_first_name, 1, 1), 
    UPPER(SUBSTRING(c.c_last_name, 1, 1)), 
    CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type), 
    ca.ca_city, 
    d.d_date, 
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male' 
        WHEN cd.cd_gender = 'F' THEN 'Female' 
        ELSE 'Other' 
    END
HAVING 
    SUM(ws.ws_sales_price) > 1000 
ORDER BY 
    total_spent DESC, transaction_date ASC;
