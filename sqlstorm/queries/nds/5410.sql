
WITH sales_data AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        sd.total_profit,
        sd.order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        sales_data sd ON c.c_customer_sk = sd.customer_id
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    ORDER BY 
        sd.total_profit DESC 
    LIMIT 10
),
customer_addresses AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS address_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
)
SELECT 
    tc.c_customer_id,
    tc.total_profit,
    tc.order_count,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    ca.ca_city,
    ca.ca_state,
    ca.address_count
FROM 
    top_customers tc
JOIN 
    customer_addresses ca ON tc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE (ca.ca_city, ca.ca_state) IN (SELECT DISTINCT ca.ca_city, ca.ca_state FROM customer_address ca)))
ORDER BY 
    tc.total_profit DESC;
