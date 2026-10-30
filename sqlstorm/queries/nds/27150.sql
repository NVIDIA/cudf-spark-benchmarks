
WITH address_details AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
customer_details AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_amount
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    ad.ca_country,
    COALESCE(ss.total_quantity, 0) AS total_purchases,
    COALESCE(ss.total_amount, 0.00) AS total_spent
FROM 
    customer_details cd
JOIN 
    customer_address ca ON cd.c_customer_sk = ca.ca_address_sk
JOIN 
    address_details ad ON ca.ca_address_sk = ad.ca_address_sk
LEFT JOIN 
    sales_summary ss ON cd.c_customer_sk = ss.ws_bill_customer_sk
WHERE 
    ad.ca_state = 'CA'
    AND cd.cd_marital_status = 'M'
ORDER BY 
    total_amount DESC
LIMIT 10;
