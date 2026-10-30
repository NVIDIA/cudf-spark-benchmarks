
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS name_length,
        CONCAT(UPPER(SUBSTRING(c.c_first_name, 1, 1)), LOWER(SUBSTRING(c.c_first_name, 2))) AS formatted_first_name,
        CONCAT(UPPER(SUBSTRING(c.c_last_name, 1, 1)), LOWER(SUBSTRING(c.c_last_name, 2))) AS formatted_last_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.name_length,
    ci.formatted_first_name,
    ci.formatted_last_name,
    COALESCE(sd.total_spent, 0) AS total_spent,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    customer_info ci
LEFT JOIN 
    sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    total_spent DESC, order_count DESC
LIMIT 50;
