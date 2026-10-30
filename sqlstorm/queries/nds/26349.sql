
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
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count
    FROM 
        customer_demographics
),
SalesData AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_paid) AS total_spent,
        COUNT(ss_ticket_number) AS purchase_count
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
DetailedReport AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ad.full_address,
        ad.ca_city,
        ad.ca_state,
        ad.ca_zip,
        ad.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        sd.total_spent,
        sd.purchase_count
    FROM 
        customer c
    JOIN AddressDetails ad ON c.c_current_addr_sk = ad.ca_address_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ss_customer_sk
)
SELECT 
    d.c_customer_id,
    d.c_first_name,
    d.c_last_name,
    d.full_address,
    d.ca_city,
    d.ca_state,
    d.ca_zip,
    d.ca_country,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_education_status,
    d.total_spent,
    d.purchase_count,
    CASE 
        WHEN d.total_spent IS NULL THEN 'No Purchases'
        WHEN d.total_spent < 1000 THEN 'Low Spender'
        WHEN d.total_spent BETWEEN 1000 AND 5000 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    DetailedReport d
ORDER BY 
    d.total_spent DESC NULLS LAST, 
    d.c_last_name ASC;
