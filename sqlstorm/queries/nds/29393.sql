
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        LOWER(ca_street_name) AS street_name_lower,
        UPPER(ca_city) AS city_upper,
        LENGTH(ca_zip) AS zip_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_state
    FROM 
        customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        REPLACE(cd_credit_rating, ' ', '') AS clean_credit_rating
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_address_sk,
    a.street_name_lower,
    a.city_upper,
    a.zip_length,
    a.full_address,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.clean_credit_rating,
    s.total_sales,
    s.order_count
FROM 
    AddressInfo a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    SalesData s ON s.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    a.ca_state = 'CA'
    AND d.cd_purchase_estimate > 5000
ORDER BY 
    s.total_sales DESC, 
    a.city_upper ASC;
