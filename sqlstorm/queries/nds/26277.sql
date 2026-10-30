
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_zip) AS zip_length
    FROM 
        customer_address
), 
DemographicDetails AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        CONCAT(cd_gender, ' - ', cd_marital_status) AS gender_marital_status
    FROM 
        customer_demographics
), 
SalesAggregate AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    ad.ca_city,
    ad.ca_state,
    ad.full_address,
    dd.gender_marital_status,
    COALESCE(sa.total_sales, 0) AS total_sales,
    COALESCE(sa.total_orders, 0) AS total_orders,
    CASE 
        WHEN dd.cd_gender = 'M' THEN 'Male'
        WHEN dd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other' 
    END AS gender_full_text
FROM 
    customer c
LEFT JOIN 
    AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN 
    DemographicDetails dd ON c.c_current_cdemo_sk = dd.cd_demo_sk
LEFT JOIN 
    SalesAggregate sa ON c.c_customer_sk = sa.ws_bill_customer_sk
WHERE 
    ad.zip_length BETWEEN 5 AND 10
ORDER BY 
    total_sales DESC, c.c_last_name ASC;
