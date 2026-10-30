
WITH AddressProcessing AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        CONCAT(ca_city, ', ', ca_state, ' ', ca_zip) AS city_state_zip,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_country) AS country_upper
    FROM 
        customer_address
), 
CustomerProcessing AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender_description
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cp.full_name,
    ap.full_address,
    ap.city_state_zip,
    ss.total_profit,
    ss.order_count,
    ap.street_name_length,
    ap.country_upper,
    cp.gender_description
FROM 
    CustomerProcessing cp
JOIN 
    AddressProcessing ap ON cp.c_customer_sk = ap.ca_address_sk
LEFT JOIN 
    SalesSummary ss ON cp.c_customer_sk = ss.customer_sk
WHERE 
    ap.full_address LIKE '%Main St%'
ORDER BY 
    ss.total_profit DESC, 
    cp.full_name ASC;
