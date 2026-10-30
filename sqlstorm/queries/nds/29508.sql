
WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS address_count,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(*) AS demographic_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        AVG(cd_dep_count) AS avg_dep_count,
        MIN(cd_credit_rating) AS min_credit_rating,
        MAX(cd_credit_rating) AS max_credit_rating
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
), 
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450000 AND 2450600 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    A.ca_state,
    A.address_count,
    A.max_street_name_length,
    A.min_street_name_length,
    A.avg_street_name_length,
    D.cd_gender,
    D.demographic_count,
    D.avg_purchase_estimate,
    D.avg_dep_count,
    D.min_credit_rating,
    D.max_credit_rating,
    S.total_sales,
    S.order_count,
    S.avg_sales_price
FROM 
    AddressStats A
JOIN 
    DemographicStats D ON A.address_count > 100
JOIN 
    SalesStats S ON D.demographic_count > 50
ORDER BY 
    A.ca_state, D.cd_gender;
