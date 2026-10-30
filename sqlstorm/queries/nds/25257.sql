
WITH RankedAddresses AS (
    SELECT
        ca_address_sk,
        ca_street_name,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY ca_city) AS city_rank
    FROM
        customer_address
    WHERE
        ca_street_name LIKE '%Street%'
),
FilteredDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM
        customer_demographics
    WHERE
        cd_purchase_estimate > 50000
),
JoinedData AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        r.ca_address_sk,
        r.ca_street_name,
        r.ca_city,
        r.ca_state,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status
    FROM
        customer c
    JOIN
        RankedAddresses r ON c.c_current_addr_sk = r.ca_address_sk
    JOIN
        FilteredDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT
    j.c_customer_id,
    CONCAT(j.c_first_name, ' ', j.c_last_name) AS full_name,
    j.ca_street_name,
    j.ca_city,
    j.ca_state,
    j.cd_gender,
    j.cd_marital_status,
    j.cd_education_status
FROM
    JoinedData j
WHERE
    j.cd_gender = 'F'
ORDER BY
    j.ca_state, j.ca_city;
