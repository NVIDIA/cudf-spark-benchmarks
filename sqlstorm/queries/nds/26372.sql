
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        CONCAT_WS(', ', ca_city, ca_county, ca_state, ca_zip, ca_country) AS location_details
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_credit_rating,
        CONCAT(cd_gender, ' - ', cd_marital_status, ' - ', cd_education_status) AS demographic_profile
    FROM 
        customer_demographics
),
SalesDetails AS (
    SELECT 
        ws_web_site_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales
    GROUP BY 
        ws_web_site_sk
)
SELECT 
    a.ca_address_id,
    a.full_address,
    a.location_details,
    d.cd_demo_sk,
    d.demographic_profile,
    s.ws_web_site_sk,
    s.total_sales,
    s.average_profit
FROM 
    AddressDetails a
JOIN 
    customer c ON a.ca_address_id = c.c_customer_id
JOIN 
    Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
JOIN 
    SalesDetails s ON c.c_customer_sk = s.ws_web_site_sk
WHERE 
    s.total_sales > 10000
ORDER BY 
    s.average_profit DESC;
