
WITH AddressDetails AS (
    SELECT 
        ca_address_id,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, ' ', cd_marital_status, ' ', cd_education_status) AS demographic_info
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_ship_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_customer_sk
)
SELECT 
    a.ca_address_id,
    a.ca_city,
    a.ca_state,
    a.full_address,
    d.demographic_info,
    s.total_sales,
    s.order_count,
    d.cd_gender,
    SUBSTRING(a.full_address, 1, 15) AS short_address,
    CASE 
        WHEN s.total_sales > 1000 THEN 'High Value'
        ELSE 'Regular'
    END AS customer_value_flag
FROM 
    AddressDetails a
JOIN 
    customer c ON a.ca_address_id = c.c_customer_id
JOIN 
    CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    SalesInfo s ON c.c_customer_sk = s.ws_ship_customer_sk
WHERE 
    a.ca_state = 'CA' 
    AND d.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC, a.ca_city;
