
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REPLACE(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip), ' ', '-') AS formatted_address,
        ca_country
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ad.full_address,
        ad.formatted_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
FinalReport AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.full_address,
        si.total_sales,
        si.order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesInfo si ON ci.c_customer_sk = si.customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 1000 THEN 'Low Value'
        WHEN total_sales >= 1000 AND total_sales < 5000 THEN 'Medium Value'
        WHEN total_sales >= 5000 THEN 'High Value'
    END AS customer_value_category
FROM 
    FinalReport
ORDER BY 
    total_sales DESC;
