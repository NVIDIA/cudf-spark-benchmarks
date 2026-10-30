
WITH CustomerName AS (
    SELECT 
        c.c_customer_sk,
        TRIM(c.c_first_name) || ' ' || TRIM(c.c_last_name) AS full_name,
        TRIM(c.c_first_name) || ' ' || TRIM(c.c_last_name) AS normalized_name
    FROM 
        customer c
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        TRIM(CONCAT_WS(' ', ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_suite_number)) AS full_address,
        TRIM(CONCAT_WS(', ', ca.ca_city, ca.ca_state, ca.ca_zip)) AS location_details
    FROM 
        customer_address ca
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS adjusted_purchase_estimate
    FROM 
        customer_demographics cd
),
AggregatedData AS (
    SELECT 
        cn.full_name,
        ad.full_address,
        ad.location_details,
        dt.d_date AS record_date,
        dm.cd_gender,
        dm.adjusted_purchase_estimate
    FROM 
        CustomerName cn
    JOIN 
        customer c ON c.c_customer_sk = cn.c_customer_sk
    JOIN 
        AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN 
        Demographics dm ON c.c_current_cdemo_sk = dm.cd_demo_sk
    JOIN 
        date_dim dt ON c.c_first_sales_date_sk = dt.d_date_sk
)
SELECT 
    full_name,
    full_address,
    location_details,
    record_date,
    COUNT(*) OVER (PARTITION BY adjusted_purchase_estimate) AS customer_count_by_estimate,
    AVG(adjusted_purchase_estimate) OVER (PARTITION BY EXTRACT(YEAR FROM record_date)) AS average_estimate_by_year,
    SUM(adjusted_purchase_estimate) OVER () AS total_estimated_purchases
FROM 
    AggregatedData
WHERE 
    record_date BETWEEN '2022-01-01' AND '2023-12-31'
ORDER BY 
    adjusted_purchase_estimate DESC;
