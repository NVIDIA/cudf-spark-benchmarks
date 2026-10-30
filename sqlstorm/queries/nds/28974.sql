
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city, 
    ca.ca_state, 
    ca.ca_country, 
    cd.cd_gender, 
    cd.cd_marital_status,
    d.d_date AS transaction_date,
    SUM(ws.ws_net_paid) AS total_spent
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
WHERE 
    d.d_date BETWEEN '2023-01-01' AND '2023-12-31'
    AND ca.ca_city IS NOT NULL
    AND ca.ca_state IN ('CA', 'NY', 'TX')
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, ca.ca_country, cd.cd_gender, cd.cd_marital_status, d.d_date
HAVING 
    SUM(ws.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC;
