WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(NULLIF(ca_suite_number, ''), '')) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
FinalData AS (
    SELECT 
        ca.full_address,
        ca.ca_city,
        ca.ca_state,
        SUM(sd.total_quantity) AS total_sales_quantity,
        SUM(sd.total_net_profit) AS total_sales_profit,
        AVG(sd.avg_net_paid) AS average_profit_per_transaction
    FROM 
        AddressData ca
    JOIN 
        CustomerData cust ON cust.c_customer_sk = ca.ca_address_sk
    JOIN 
        SalesData sd ON sd.ws_item_sk = cust.c_customer_sk 
    GROUP BY 
        ca.full_address, ca.ca_city, ca.ca_state
)
SELECT 
    full_address,
    ca_city,
    ca_state,
    total_sales_quantity,
    total_sales_profit,
    average_profit_per_transaction
FROM 
    FinalData
WHERE 
    total_sales_quantity > 1000
ORDER BY 
    total_sales_profit DESC;