
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(UPPER(ca_street_number), ' ', TRIM(UPPER(ca_street_name)), ' ', UPPER(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', UPPER(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        CA_zip
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(UPPER(c.c_salutation), ' ', UPPER(c.c_first_name), ' ', UPPER(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
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
    c.full_name,
    a.full_address,
    a.ca_city,
    a.ca_state,
    s.total_sales,
    s.total_orders
FROM 
    CustomerData c
JOIN 
    AddressData a ON c.c_customer_sk = a.ca_address_sk
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    a.ca_state = 'CA'
ORDER BY 
    s.total_sales DESC
LIMIT 10;
