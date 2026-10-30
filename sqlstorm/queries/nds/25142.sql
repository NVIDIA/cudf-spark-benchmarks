
WITH AddressCTE AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS address_length
    FROM 
        customer_address
),
GenderCTE AS (
    SELECT 
        cd_gender,
        COUNT(*) AS gender_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
DemographicCTE AS (
    SELECT 
        cd_gender,
        SUM(cd_purchase_estimate) AS total_estimate,
        AVG(cd_dep_count) AS avg_deps,
        MAX(cd_credit_rating) AS max_credit_rating,
        MIN(cd_credit_rating) AS min_credit_rating
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
SalesCTE AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.full_address,
    a.address_length,
    g.gender_count,
    d.total_estimate,
    d.avg_deps,
    s.total_sales,
    s.total_orders
FROM 
    AddressCTE a
JOIN 
    GenderCTE g ON g.gender_count > 50
JOIN 
    DemographicCTE d ON d.cd_gender = g.cd_gender
LEFT JOIN 
    SalesCTE s ON s.ws_bill_customer_sk = a.ca_address_sk
WHERE 
    a.address_length > 100
ORDER BY 
    a.address_length DESC, 
    s.total_sales DESC;
