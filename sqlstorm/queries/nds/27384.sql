
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(ws.ws_quantity) AS total_quantity_purchased,
    SUM(ws.ws_net_paid) AS total_spent,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    DENSE_RANK() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_net_paid) DESC) AS city_spending_rank
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, 
    cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_city
HAVING 
    SUM(ws.ws_quantity) > 0
    AND SUM(ws.ws_net_paid) > 1000
ORDER BY 
    total_spent DESC, customer_full_name;
