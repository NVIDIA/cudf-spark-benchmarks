
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip
    FROM 
        customer_address
),
filtered_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'M' AND cd.cd_marital_status = 'S'
),
aggregate_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    fa.customer_name,
    fa.cd_gender,
    fa.cd_marital_status,
    pa.full_address,
    ag.total_profit,
    ag.order_count
FROM 
    filtered_customers fa
JOIN 
    processed_addresses pa ON pa.ca_address_sk = fa.c_customer_sk
LEFT JOIN 
    aggregate_sales ag ON ag.ws_bill_customer_sk = fa.c_customer_sk
WHERE 
    ag.total_profit > 1000
ORDER BY 
    ag.total_profit DESC;
