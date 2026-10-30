
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_country LIKE '%USA%'
),
DemographicDetails AS (
    SELECT 
        CONCAT(cd_gender, ' ', cd_marital_status) AS demographic_info,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate > 5000
),
SalesSummary AS (
    SELECT 
        s_store_name,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions
    FROM 
        store_sales
    JOIN 
        store ON store.s_store_sk = store_sales.ss_store_sk
    GROUP BY 
        s_store_name
)
SELECT 
    a.full_address,
    a.ca_city,
    a.ca_state,
    a.ca_zip,
    a.ca_country,
    d.demographic_info,
    d.cd_purchase_estimate,
    d.cd_credit_rating,
    s.s_store_name,
    s.total_sales,
    s.total_transactions
FROM 
    AddressDetails a
JOIN 
    DemographicDetails d ON d.cd_purchase_estimate > 5000
JOIN 
    SalesSummary s ON s.total_sales > 100000
ORDER BY 
    s.total_sales DESC;
