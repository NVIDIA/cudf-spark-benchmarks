
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name) AS short_address
    FROM 
        customer_address ca
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(cd.cd_gender, '_', cd.cd_marital_status) AS gender_marital,
        CASE 
            WHEN cd.cd_purchase_estimate BETWEEN 0 AND 1000 THEN 'low'
            WHEN cd.cd_purchase_estimate BETWEEN 1001 AND 5000 THEN 'medium'
            ELSE 'high'
        END AS purchase_band
    FROM 
        customer_demographics cd
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    d.gender_marital,
    d.purchase_band,
    s.total_sales,
    s.total_profit
FROM 
    AddressDetails a
JOIN 
    customer c ON c.c_current_addr_sk = a.ca_address_sk
JOIN 
    CustomerDemographics d ON d.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    SalesData s ON s.ws_item_sk = c.c_customer_sk
WHERE 
    a.ca_state = 'CA' 
    AND d.cd_gender = 'F' 
ORDER BY 
    s.total_profit DESC
LIMIT 100;
