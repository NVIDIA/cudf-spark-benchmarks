
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(', Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country,
        LENGTH(ca_street_name) AS street_name_length,
        LENGTH(ca_city) AS city_length
    FROM
        customer_address
),
DemographicDetails AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_text
    FROM
        customer_demographics
),
FilteredCustomers AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        a.full_address,
        d.gender_text,
        d.cd_credit_rating,
        d.cd_purchase_estimate
    FROM
        customer c
    JOIN 
        AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
    JOIN 
        DemographicDetails d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE
        d.cd_purchase_estimate > 5000
        AND UPPER(a.ca_city) LIKE 'N%'
)
SELECT
    f.customer_name,
    f.full_address,
    f.gender_text,
    f.cd_credit_rating,
    f.cd_purchase_estimate,
    COUNT(*) OVER (PARTITION BY f.gender_text) AS gender_count,
    SUM(f.cd_purchase_estimate) OVER () AS total_estimate
FROM
    FilteredCustomers f
ORDER BY
    f.cd_purchase_estimate DESC
LIMIT 10;
