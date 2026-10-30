
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city AS city,
    ca.ca_state AS state,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_ext_sales_price) AS total_spent,
    MAX(ws.ws_sold_date_sk) AS last_order_date,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    DENSE_RANK() OVER (PARTITION BY ca.ca_state ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS spending_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_country = 'USA'
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
HAVING 
    COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC 
LIMIT 100;
