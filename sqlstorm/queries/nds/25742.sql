
WITH AddressDetails AS (
    SELECT 
        ca_address_sk, 
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
CombinedDetails AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        sd.total_orders,
        sd.total_quantity_sold,
        sd.total_net_profit
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_item_sk
)
SELECT 
    full_name,
    full_address,
    ca_city,
    ca_state,
    total_orders,
    total_quantity_sold,
    total_net_profit
FROM 
    CombinedDetails
WHERE 
    ca_state = 'CA' AND 
    total_orders > 5
ORDER BY 
    total_net_profit DESC
LIMIT 10;
