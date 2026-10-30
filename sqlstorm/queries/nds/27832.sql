
WITH AddressDetails AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
GenderStatistics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM 
        customer_demographics
    JOIN 
        customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesSummary AS (
    SELECT 
        ws_ship_mode_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(*) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_ship_mode_sk
)
SELECT 
    AD.full_address,
    AD.ca_city,
    AD.ca_state,
    GD.cd_gender,
    GD.customer_count,
    GD.total_dependents,
    SS.total_sales,
    SS.sales_count
FROM 
    AddressDetails AD
JOIN 
    GenderStatistics GD ON GD.customer_count > 0
JOIN 
    SalesSummary SS ON SS.sales_count > 0
WHERE 
    AD.ca_state = 'CA' 
    AND GD.cd_gender = 'F'
ORDER BY 
    SS.total_sales DESC
LIMIT 50;
