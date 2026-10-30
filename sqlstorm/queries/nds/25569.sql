WITH AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        LOWER(SUBSTR(ca.ca_city, 1, 3)) AS city_prefix,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
),
CombinedData AS (
    SELECT 
        ad.full_address,
        ad.city_prefix,
        ad.ca_state,
        ad.ca_zip,
        sd.total_sales_quantity,
        sd.total_net_profit,
        cd.gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        AddressDetails ad
    JOIN 
        SalesData sd ON ad.ca_address_sk = sd.ws_item_sk 
    JOIN 
        CustomerDemographics cd ON sd.ws_item_sk = cd.cd_demo_sk 
)
SELECT 
    city_prefix,
    ca_state,
    COUNT(DISTINCT full_address) AS address_count,
    SUM(total_sales_quantity) AS total_quantity_sold,
    AVG(total_net_profit) AS avg_net_profit,
    COUNT(DISTINCT gender) AS unique_genders,
    COUNT(DISTINCT cd_marital_status) AS unique_marital_statuses,
    COUNT(DISTINCT cd_education_status) AS unique_education_statuses
FROM 
    CombinedData
GROUP BY 
    city_prefix, 
    ca_state
ORDER BY 
    city_prefix, 
    ca_state;