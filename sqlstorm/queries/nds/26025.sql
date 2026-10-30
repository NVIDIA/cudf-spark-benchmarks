
WITH ProcessedAddresses AS (
    SELECT 
        ca_address_sk,
        CONCAT(
            TRIM(ca_street_number), ' ', 
            TRIM(ca_street_name), ' ', 
            TRIM(ca_street_type), ', ', 
            TRIM(ca_city), ', ', 
            TRIM(ca_state), ' ', 
            TRIM(ca_zip), ', ', 
            TRIM(ca_country)
        ) AS full_address
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ca.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        ProcessedAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
FinalOutput AS (
    SELECT 
        cd.customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sd.total_quantity,
        sd.total_profit,
        sd.total_orders,
        cd.full_address
    FROM 
        CustomerDetails cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_profit IS NULL THEN 'No Sales'
        WHEN total_profit > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer' 
    END AS customer_category
FROM 
    FinalOutput
ORDER BY 
    total_profit DESC;
