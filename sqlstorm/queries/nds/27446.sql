
WITH AddressComponents AS (
    SELECT 
        ca_address_sk,
        TRIM(ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type || 
             CASE WHEN ca_suite_number IS NOT NULL THEN ' Suite ' || ca_suite_number ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
DemographicGroups AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_category
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_quantity,
        AVG(ss.ss_sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.purchase_category,
    s.total_sales,
    s.total_quantity,
    s.avg_sales_price
FROM 
    AddressComponents a
JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
JOIN 
    DemographicGroups d ON c.c_current_cdemo_sk = d.cd_demo_sk
LEFT JOIN 
    SalesData s ON c.c_customer_sk = s.c_customer_sk
WHERE 
    a.ca_state = 'CA' 
    AND d.cd_gender = 'F'
ORDER BY 
    s.total_sales DESC
LIMIT 100;
