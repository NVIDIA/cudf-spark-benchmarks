
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        UPPER(ca_country) AS country_uppercase
    FROM
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_salutation), ' ', TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
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
    cd.full_name,
    ac.full_address,
    ac.ca_city,
    ac.ca_state,
    ac.country_uppercase,
    sd.total_sales,
    sd.order_count
FROM 
    CustomerDetails cd
JOIN 
    AddressComponents ac ON cd.c_customer_sk = ac.ca_address_sk
LEFT JOIN 
    SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F' AND 
    cd.cd_marital_status = 'M' AND 
    sd.total_sales > 1000
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
