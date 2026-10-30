
WITH ranked_addresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_street_number) AS address_rank
    FROM 
        customer_address
    WHERE 
        ca_country = 'USA'
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS customer_full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ra.full_address AS customer_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        ranked_addresses ra ON c.c_current_addr_sk = ra.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
)
SELECT 
    ci.customer_full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.customer_address,
    COUNT(ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
GROUP BY 
    ci.customer_full_name, ci.cd_gender, ci.cd_marital_status, ci.customer_address
HAVING 
    COUNT(ws.ws_order_number) > 5
ORDER BY 
    total_spent DESC
LIMIT 10;
