WITH AddressStats AS (
    SELECT 
        ca_state,
        COUNT(*) AS total_addresses,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_city)) AS max_city_length,
        MIN(LENGTH(ca_street_number)) AS min_street_number_length
    FROM 
        customer_address
    GROUP BY 
        ca_state
), 
CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_id) AS total_customers,
        AVG(cd_dep_count) AS avg_dependents,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics 
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
), 
SalesStats AS (
    SELECT 
        d_year,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_quantity) AS avg_quantity_sold
    FROM 
        web_sales 
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year
)
SELECT 
    A.ca_state,
    A.total_addresses,
    A.avg_street_name_length,
    A.max_city_length,
    A.min_street_number_length,
    C.cd_gender,
    C.total_customers,
    C.avg_dependents,
    C.total_purchase_estimate,
    S.d_year,
    S.total_sales,
    S.avg_quantity_sold
FROM 
    AddressStats A
JOIN 
    CustomerStats C ON A.total_addresses > 100  
JOIN 
    SalesStats S ON S.total_sales > 10000      
ORDER BY 
    A.ca_state, C.cd_gender, S.d_year;