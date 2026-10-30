
WITH Address_City AS (
    SELECT DISTINCT
        ca_city,
        ca_state,
        LENGTH(ca_street_name) AS street_name_length,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_country) AS country_uppercase
    FROM
        customer_address
),
Demographics AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        COUNT(*) AS total_customers,
        MAX(cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd_dep_count) AS average_dependents
    FROM
        customer_demographics
    GROUP BY
        cd_gender, cd_marital_status, cd_education_status
),
Sales_Data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        MIN(ws_sales_price) AS min_sales_price,
        MAX(ws_sales_price) AS max_sales_price
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.ca_city,
    a.ca_state,
    d.cd_gender,
    d.cd_marital_status,
    s.total_profit,
    s.total_orders,
    s.min_sales_price,
    s.max_sales_price,
    a.street_name_length,
    a.full_address,
    a.country_uppercase
FROM 
    Address_City a
JOIN 
    Demographics d ON a.ca_state = 'CA' 
JOIN 
    Sales_Data s ON d.cd_gender = 'F' 
WHERE
    a.street_name_length > 10
ORDER BY 
    s.total_profit DESC, 
    s.total_orders DESC
LIMIT 100;
