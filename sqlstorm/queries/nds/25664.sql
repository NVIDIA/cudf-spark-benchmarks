
WITH AddressParts AS (
    SELECT DISTINCT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        ci.customer_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        si.total_sales,
        si.total_orders,
        ap.full_address
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesData si ON ci.c_customer_sk = si.ws_bill_customer_sk
    LEFT JOIN 
        AddressParts ap ON ci.c_customer_sk = ap.ca_address_sk
)
SELECT 
    customer_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    full_address
FROM 
    CombinedInfo
WHERE 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
