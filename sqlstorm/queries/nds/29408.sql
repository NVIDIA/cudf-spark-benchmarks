
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, ca.ca_city, 
        ca.ca_state, ca.ca_country, ca.ca_zip
),
HighValueCustomers AS (
    SELECT 
        * 
    FROM 
        CustomerInfo 
    WHERE 
        total_profit > 1000
)
SELECT 
    full_name,
    cd_gender AS gender,
    cd_marital_status AS marital_status,
    cd_education_status AS education_status,
    ca_city AS city,
    ca_state AS state,
    ca_country AS country,
    ca_zip AS zip,
    total_orders,
    total_profit
FROM 
    HighValueCustomers
ORDER BY 
    total_profit DESC, full_name
LIMIT 100;
