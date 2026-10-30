
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),

CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics d 
    ON 
        c.c_current_cdemo_sk = d.cd_demo_sk
),

SalesDetails AS (
    SELECT 
        s.ss_customer_sk,
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS total_transactions
    FROM 
        store_sales s
    GROUP BY 
        s.ss_customer_sk
)

SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ad.full_address,
    ad.ca_city,
    ad.ca_state,
    ad.ca_zip,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(sd.total_transactions, 0) AS total_transactions
FROM 
    CustomerInfo ci
LEFT JOIN 
    AddressDetails ad ON ci.c_customer_sk = ad.ca_address_sk
LEFT JOIN 
    SalesDetails sd ON ci.c_customer_sk = sd.ss_customer_sk
WHERE 
    ci.cd_purchase_estimate > 1000 
ORDER BY 
    total_sales DESC, ci.full_name ASC
LIMIT 100;
