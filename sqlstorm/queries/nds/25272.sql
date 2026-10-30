
WITH RankedAddresses AS (
    SELECT
        ca_address_sk,
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        RANK() OVER (PARTITION BY ca_city ORDER BY ca_street_number) AS addr_rank
    FROM customer_address
),
NameFilteredCustomers AS (
    SELECT
        c_customer_sk,
        c_first_name || ' ' || c_last_name AS full_name,
        c_email_address,
        c_birth_day,
        c_birth_month,
        c_birth_year
    FROM customer
    WHERE c_first_name LIKE 'A%'
),
GenderDemo AS (
    SELECT
        cd_demo_sk,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender_desc
    FROM customer_demographics
),
CustomerDemographics AS (
    SELECT
        nc.c_customer_sk,
        nc.full_name,
        nc.c_email_address,
        gd.gender_desc,
        na.full_address,
        nc.c_birth_day,
        nc.c_birth_month,
        nc.c_birth_year
    FROM NameFilteredCustomers nc
    JOIN GenderDemo gd ON nc.c_customer_sk = gd.cd_demo_sk
    JOIN RankedAddresses na ON na.addr_rank = 1 
)
SELECT
    full_name,
    c_email_address,
    gender_desc,
    full_address,
    CONCAT('Date of Birth: ', LPAD(CAST(c_birth_day AS STRING), 2, '0'), '/', LPAD(CAST(c_birth_month AS STRING), 2, '0'), '/', c_birth_year) AS formatted_dob
FROM CustomerDemographics
ORDER BY gender_desc, full_name;
