
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT(ca.ca_city, ', ', ca.ca_state) AS full_address,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
highest_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    ORDER BY 
        total_profit DESC
    LIMIT 10
),
final_benchmark AS (
    SELECT 
        ci.full_name,
        ci.full_address,
        ci.cd_gender,
        ci.cd_marital_status,
        hs.total_profit
    FROM 
        customer_info ci
    JOIN 
        highest_sales hs ON ci.c_customer_sk = hs.ws_bill_customer_sk
    WHERE 
        ci.rn = 1
)
SELECT 
    full_name,
    SUBSTRING(full_address, POSITION(',' IN full_address) + 2) AS ca_city,
    cd_gender,
    cd_marital_status,
    total_profit,
    LENGTH(full_name) AS name_length,
    INITCAP(full_name) AS capitalized_name,
    REPLACE(full_address, ' ', '-') AS address_with_hyphens
FROM 
    final_benchmark
ORDER BY 
    total_profit DESC;
