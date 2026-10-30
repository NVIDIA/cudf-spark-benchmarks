
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_state IN ('CA', 'NY', 'TX')
),
DemographicData AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        UPPER(cd_marital_status) AS marital_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM 
        customer_demographics
    WHERE 
        cd_gender = 'F' AND cd_purchase_estimate > 1000
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
    AD.full_address,
    DD.marital_status,
    DD.cd_gender,
    SD.total_sales,
    SD.order_count
FROM 
    AddressData AD
JOIN 
    customer C ON AD.ca_address_sk = C.c_current_addr_sk
JOIN 
    DemographicData DD ON C.c_current_cdemo_sk = DD.cd_demo_sk
JOIN 
    SalesData SD ON C.c_customer_sk = SD.ws_bill_customer_sk
WHERE 
    SD.total_sales > 5000
ORDER BY 
    DD.cd_purchase_estimate DESC, 
    AD.ca_city, 
    AD.ca_state;
