
WITH AddressEnhanced AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
CustomerProfile AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        ad.address_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressEnhanced ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesOverview AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_ext_sales_price) AS average_order_value
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cp.full_name,
    cp.cd_gender,
    cp.cd_marital_status,
    cp.cd_education_status,
    cp.full_address,
    cp.ca_city,
    cp.ca_state,
    cp.ca_zip,
    cp.ca_country,
    so.total_sales,
    so.total_orders,
    so.average_order_value,
    CASE 
        WHEN so.total_sales > 1000 THEN 'High Value'
        WHEN so.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    CustomerProfile cp
LEFT JOIN 
    SalesOverview so ON cp.c_customer_sk = so.ws_bill_customer_sk
WHERE 
    cp.address_length > 20
ORDER BY 
    so.total_sales DESC
LIMIT 100;
