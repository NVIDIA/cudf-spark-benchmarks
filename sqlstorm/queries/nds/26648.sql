
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
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss_ticket_number) AS total_purchases
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
)
SELECT 
    cd.full_name,
    ad.full_address,
    ad.ca_zip,
    ss.total_spent,
    ss.total_purchases
FROM 
    AddressDetails ad
JOIN 
    CustomerDetails cd ON ad.ca_address_sk = cd.c_customer_sk
JOIN 
    SalesSummary ss ON cd.c_customer_sk = ss.ss_customer_sk
WHERE 
    ss.total_spent > 1000
ORDER BY 
    ss.total_spent DESC
LIMIT 50;
