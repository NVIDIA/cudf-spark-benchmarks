
WITH address_parts AS (
    SELECT 
        ca_address_sk, 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', COALESCE(ca_suite_number, '')) AS full_address,
        ca_city,
        ca_state,
        SUBSTRING(ca_zip, 1, 5) AS zip_prefix
    FROM 
        customer_address
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        CASE 
            WHEN cd.cd_purchase_estimate < 100 THEN 'Low'
            WHEN cd.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
            ELSE 'High'
        END AS spend_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        address_parts ad ON c.c_current_addr_sk = ad.ca_address_sk
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.spend_category,
    sd.total_sales
FROM 
    customer_details cd
LEFT JOIN 
    sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
WHERE 
    cd.ca_state = 'CA' AND 
    (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F')
ORDER BY 
    total_sales DESC;
