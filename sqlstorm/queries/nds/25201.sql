
WITH AddressDetails AS (
    SELECT 
        ca_city,
        ca_state,
        ca_zip,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS address_length
    FROM 
        customer_address
),
FilteredAddresses AS (
    SELECT 
        ca_city,
        ca_state,
        ca_zip,
        full_address,
        address_length
    FROM 
        AddressDetails
    WHERE 
        address_length > 50
),
DemographicSummary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender, cd_marital_status
)
SELECT 
    fa.ca_city,
    fa.ca_state,
    fa.ca_zip,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.customer_count,
    ds.total_dependents,
    CONCAT(fa.full_address, ' - Customers: ', ds.customer_count) AS address_customers
FROM 
    FilteredAddresses fa
LEFT JOIN 
    DemographicSummary ds ON fa.ca_city = ds.cd_gender
ORDER BY 
    fa.ca_city, fa.ca_state;
