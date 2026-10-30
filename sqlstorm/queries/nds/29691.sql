
WITH address_info AS (
    SELECT 
        ca_city,
        ca_state,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_street_name) AS upper_street_name,
        COALESCE(NULLIF(ca_suite_number, ''), 'N/A') AS suite_info
    FROM 
        customer_address
    WHERE 
        ca_city LIKE '%town%'
),

demographics_info AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        CONCAT(cd_gender, ' - ', cd_marital_status) AS gender_marital_status,
        COUNT(*) AS demographic_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender,
        cd_marital_status
),

sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws_order_number) AS unique_orders
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
)

SELECT 
    ai.ca_city,
    ai.ca_state,
    ai.street_name_length,
    ai.upper_street_name,
    ai.suite_info,
    di.gender_marital_status,
    di.demographic_count,
    si.total_net_paid,
    si.avg_sales_price,
    si.unique_orders
FROM 
    address_info ai
JOIN 
    demographics_info di ON ai.ca_state = 'CA' 
JOIN 
    sales_info si ON si.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_birth_country = 'USA')
ORDER BY 
    si.total_net_paid DESC, 
    di.demographic_count DESC
LIMIT 100;
