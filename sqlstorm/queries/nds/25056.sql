
WITH AddressParts AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(', Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        CONCAT(TRIM(ca_city), ', ', TRIM(ca_state), ' ', TRIM(ca_zip), ', ', TRIM(ca_country)) AS location_info
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.location_info
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressParts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.full_address,
    cd.location_info,
    COALESCE(si.total_orders, 0) AS total_orders,
    COALESCE(si.total_sales, 0) AS total_sales
FROM 
    CustomerDetails cd
LEFT JOIN 
    SalesInfo si ON cd.c_customer_sk = si.ws_bill_customer_sk
WHERE 
    cd.cd_gender = 'F' 
    AND cd.cd_marital_status = 'M'
ORDER BY 
    total_sales DESC
LIMIT 20;
