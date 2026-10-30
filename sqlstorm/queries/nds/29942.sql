
WITH address_info AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
), 
demographics_info AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        CASE 
            WHEN cd_purchase_estimate < 1000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_band
    FROM 
        customer_demographics
),
sales_summary AS (
    SELECT 
        ws_bill_cdemo_sk AS demo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
)
SELECT 
    ai.ca_address_sk,
    ai.full_address,
    ai.ca_city,
    ai.ca_state,
    di.cd_gender,
    di.cd_marital_status,
    di.cd_education_status,
    di.purchase_band,
    ss.total_sales,
    ss.order_count
FROM 
    address_info ai
JOIN 
    customer c ON ai.ca_address_sk = c.c_current_addr_sk
JOIN 
    demographics_info di ON c.c_current_cdemo_sk = di.cd_demo_sk
LEFT JOIN 
    sales_summary ss ON di.cd_demo_sk = ss.demo_sk
WHERE 
    ai.ca_state = 'NY'
ORDER BY 
    ss.total_sales DESC
LIMIT 50;
