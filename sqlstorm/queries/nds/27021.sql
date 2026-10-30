
WITH RankedAddresses AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS addr_rank
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedResults AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        s.total_profit,
        ra.ca_city,
        ra.ca_state
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesSummary s ON cd.c_customer_sk = s.ws_bill_customer_sk
    LEFT JOIN 
        RankedAddresses ra ON cd.c_customer_sk = ra.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    total_profit,
    ca_city,
    ca_state
FROM 
    CombinedResults
WHERE 
    total_profit IS NOT NULL
ORDER BY 
    total_profit DESC, ca_city;
