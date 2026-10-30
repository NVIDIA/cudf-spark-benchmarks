
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
), 
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM 
        customer_demographics
), 
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
) 
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    dm.cd_gender,
    dm.cd_marital_status,
    dm.cd_education_status,
    dm.cd_purchase_estimate,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.order_count, 0) AS order_count
FROM 
    customer c
JOIN 
    AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
JOIN 
    DemographicDetails dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
LEFT JOIN 
    SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    dm.cd_gender = 'F' 
    AND dm.cd_marital_status = 'S'
ORDER BY 
    total_sales DESC, c.c_last_name;
