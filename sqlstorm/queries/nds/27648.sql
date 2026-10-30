
WITH Combined_Customer_Data AS (
    SELECT 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(cd.cd_dep_count, 0) AS dep_count,
        COALESCE(cd.cd_dep_employed_count, 0) AS dep_employed_count,
        c.c_customer_sk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Sales_Data AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
Final_Benchmark AS (
    SELECT 
        c.full_name,
        c.ca_city,
        c.ca_state,
        c.cd_gender,
        c.cd_marital_status,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        c.purchase_estimate,
        (c.dep_count + c.dep_employed_count) AS total_deps
    FROM 
        Combined_Customer_Data c
    LEFT JOIN 
        Sales_Data s ON c.c_customer_sk = s.customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    total_net_profit,
    purchase_estimate,
    total_deps,
    CASE 
        WHEN total_net_profit > purchase_estimate THEN 'Profit Above Est.'
        WHEN total_net_profit < purchase_estimate THEN 'Loss Below Est.'
        ELSE 'Break Even'
    END AS profit_analysis
FROM 
    Final_Benchmark
ORDER BY 
    total_net_profit DESC, 
    full_name ASC
LIMIT 100;
