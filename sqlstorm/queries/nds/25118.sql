
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL
),
DemoInfo AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographic_profile
    FROM 
        customer_demographics
),
SalesInfo AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        d.demographic_profile,
        s.total_sales,
        s.order_count
    FROM 
        customer c
    JOIN 
        AddressInfo a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemoInfo d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN 
        SalesInfo s ON c.c_customer_sk = s.ws_bill_customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.full_address,
    c.demographic_profile,
    COALESCE(c.total_sales, 0) AS total_sales,
    COALESCE(c.order_count, 0) AS order_count,
    CASE 
        WHEN COALESCE(c.total_sales, 0) = 0 THEN 'No Purchases'
        WHEN COALESCE(c.total_sales, 0) < 100 THEN 'Low Value Customer'
        WHEN COALESCE(c.total_sales, 0) BETWEEN 100 AND 500 THEN 'Medium Value Customer'
        ELSE 'High Value Customer'
    END AS customer_category
FROM 
    CustomerInfo c
ORDER BY 
    total_sales DESC;
