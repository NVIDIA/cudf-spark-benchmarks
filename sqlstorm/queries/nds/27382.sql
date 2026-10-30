
WITH AddressStats AS (
    SELECT 
        ca_city,
        ca_state,
        COUNT(*) AS address_count,
        AVG(LENGTH(ca_street_name)) AS avg_street_name_length,
        MAX(LENGTH(ca_street_name)) AS max_street_name_length,
        MIN(LENGTH(ca_street_name)) AS min_street_name_length
    FROM 
        customer_address
    GROUP BY 
        ca_city, ca_state
), 
CustomerStats AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(*) AS customer_count,
        SUM(cd_dep_count) AS total_dependencies
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, cd_marital_status
),
SalesStats AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS web_sales_count,
        SUM(ws_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    a.address_count,
    a.avg_street_name_length,
    c.cd_gender,
    c.cd_marital_status,
    c.customer_count,
    s.web_sales_count,
    s.total_sales
FROM 
    AddressStats a
JOIN 
    CustomerStats c ON a.address_count > 50
LEFT JOIN 
    SalesStats s ON c.customer_count > 10 AND c.customer_count = s.web_sales_count
WHERE 
    a.address_count > 5
ORDER BY 
    a.ca_city, c.cd_gender;
