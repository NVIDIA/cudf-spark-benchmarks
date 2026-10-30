
WITH AddressDetails AS (
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
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesDetails AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent 
    FROM 
        web_sales  
    GROUP BY 
        ws_bill_customer_sk
),
Benchmark AS (
    SELECT 
        cd.full_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        sd.total_spent,
        CASE 
            WHEN sd.total_spent > 1000 THEN 'High Value'
            WHEN sd.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        CustomerDetails cd
    JOIN 
        AddressDetails ad ON cd.c_customer_sk = ad.ca_address_sk
    LEFT JOIN 
        SalesDetails sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    customer_value_category,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS average_spent
FROM 
    Benchmark
GROUP BY 
    customer_value_category
ORDER BY 
    customer_value_category;
