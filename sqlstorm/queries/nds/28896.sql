
WITH Address_Extracted AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        REGEXP_REPLACE(ca_city, '[^A-Za-z0-9 ]+', '') AS sanitized_city,
        ca_state,
        UPPER(TRIM(ca_country)) AS normalized_country
    FROM 
        customer_address
),
Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        CONCAT(cd.cd_education_status, ' - ', cd.cd_marital_status) AS education_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer_demographics cd
),
Sales_Data AS (
    SELECT 
        ws_bill_customer_sk AS customer_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    a.full_address,
    c.gender,
    c.education_marital_status,
    COALESCE(s.total_quantity, 0) AS total_quantity,
    COALESCE(s.total_sales, 0) AS total_sales,
    a.normalized_country
FROM 
    Address_Extracted a
JOIN 
    Customer_Demographics c ON a.ca_address_sk = c.cd_demo_sk
LEFT JOIN 
    Sales_Data s ON c.cd_demo_sk = s.customer_id
WHERE 
    a.sanitized_city LIKE 'San%'
ORDER BY 
    total_sales DESC
LIMIT 100;
