
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws.ws_bill_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalBenchmark AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        si.total_orders,
        si.total_profit,
        ci.ca_city || ', ' || ci.ca_state AS full_address,
        CASE 
            WHEN si.total_profit > 1000 THEN 'High'
            WHEN si.total_profit BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    total_orders,
    total_profit,
    full_address,
    profit_category
FROM 
    FinalBenchmark
ORDER BY 
    total_profit DESC, 
    full_name;
