
WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type || 
        CASE WHEN ca.ca_suite_number IS NOT NULL THEN ' Suite ' || ca.ca_suite_number END AS full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_address ca
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_date_sk
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ss.total_quantity,
    ss.total_sales
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON ad.ca_address_sk = cd.c_customer_sk
JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ws_ship_date_sk
WHERE 
    ad.ca_state = 'CA' 
    AND cd.cd_gender = 'F'
    AND ss.total_sales > 1000
ORDER BY 
    ss.total_sales DESC
LIMIT 10;
