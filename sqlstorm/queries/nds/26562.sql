
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        s.total_sales,
        s.order_count
    FROM 
        customer c
    JOIN 
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesInfo s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    ci.c_customer_sk,
    CONCAT(ci.c_first_name, ' ', ci.c_last_name) AS full_name,
    ci.full_address,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    COALESCE(ci.total_sales, 0) AS total_sales,
    COALESCE(ci.order_count, 0) AS order_count,
    ROW_NUMBER() OVER (ORDER BY COALESCE(ci.total_sales, 0) DESC) AS sales_rank
FROM 
    CombinedInfo ci
WHERE 
    ci.cd_gender = 'F'
ORDER BY 
    sales_rank
LIMIT 10;
