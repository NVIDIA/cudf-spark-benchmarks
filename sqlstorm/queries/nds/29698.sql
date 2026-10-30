
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
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
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
),
SalesStats AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(*) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        ci.full_address,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesStats ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    c.c_customer_sk AS customer_sk,
    c.c_first_name AS first_name,
    c.c_last_name AS last_name,
    c.cd_gender AS gender,
    c.cd_marital_status AS marital_status,
    c.cd_education_status AS education_status,
    c.cd_purchase_estimate AS purchase_estimate,
    c.full_address,
    c.total_sales,
    c.order_count
FROM 
    CustomerBenchmark c
WHERE 
    c.total_sales > 1000
ORDER BY 
    c.total_sales DESC
LIMIT 100;
