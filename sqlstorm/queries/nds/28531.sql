
WITH CustomerInfo AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        ca.ca_city,
        ca.ca_state,
        DATE_PART('year', DATE '2002-10-01') - c.c_birth_year AS age,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_education_status LIKE '%Bachelor%'
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerSales AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.ca_city,
        ci.ca_state,
        ci.age,
        COALESCE(si.total_profit, 0) AS total_profit
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    ca_city,
    ca_state,
    age,
    total_profit
FROM 
    CustomerSales
WHERE 
    total_profit > 1000
ORDER BY 
    total_profit DESC
LIMIT 50;
