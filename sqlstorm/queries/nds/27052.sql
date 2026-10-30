
WITH base_data AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        'Total Orders: ' || COUNT(ws.ws_order_number) AS order_summary,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status
),
address_count AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_sk) AS unique_addresses
    FROM 
        customer_address ca
    GROUP BY 
        ca.ca_state
),
gender_stats AS (
    SELECT 
        cd.cd_gender,
        COUNT(c.c_customer_sk) AS gender_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    b.full_name,
    b.ca_city,
    b.ca_state,
    b.cd_gender,
    b.cd_marital_status,
    b.order_summary,
    b.total_spent,
    a.unique_addresses,
    g.gender_count
FROM 
    base_data b
JOIN 
    address_count a ON b.ca_state = a.ca_state
JOIN 
    gender_stats g ON b.cd_gender = g.cd_gender
ORDER BY 
    b.total_spent DESC
LIMIT 100;
