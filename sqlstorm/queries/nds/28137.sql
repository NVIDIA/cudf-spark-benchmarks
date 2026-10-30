
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(ca_city) AS city,
        LOWER(ca_state) AS state,
        ca_country
    FROM 
        customer_address
),
Demographics AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographic_profile,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_college_count
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CombinedInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        d.demographic_profile,
        s.total_sales,
        s.order_count
    FROM 
        customer c
    JOIN 
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        Demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesInfo s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    customer_name,
    full_address,
    demographic_profile,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count
FROM 
    CombinedInfo
WHERE 
    full_address LIKE '%Street%'
AND 
    total_sales > 1000
ORDER BY 
    total_sales DESC
LIMIT 50;
