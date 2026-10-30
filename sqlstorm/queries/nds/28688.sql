
WITH AddressConcatenation AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM 
        customer_address
),
GenderDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status
    FROM 
        customer_demographics
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        a.full_address,
        g.cd_gender,
        g.cd_marital_status,
        g.cd_education_status
    FROM 
        customer c
    JOIN AddressConcatenation a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN GenderDemographics g ON c.c_current_cdemo_sk = g.cd_demo_sk
),
SalesData AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_customer_sk
),
CustomerBenchmark AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.full_address,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        COALESCE(sd.total_spent, 0) AS total_spent,
        COALESCE(sd.purchase_count, 0) AS purchase_count
    FROM 
        CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ss_customer_sk
)
SELECT 
    cb.c_customer_sk,
    cb.c_first_name,
    cb.c_last_name,
    cb.full_address,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.cd_education_status,
    cb.total_spent,
    cb.purchase_count,
    CASE 
        WHEN cb.total_spent > 1000 THEN 'High Value'
        WHEN cb.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_segment
FROM 
    CustomerBenchmark cb
ORDER BY 
    total_spent DESC, c_last_name, c_first_name
LIMIT 100;
