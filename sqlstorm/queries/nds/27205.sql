
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        (SELECT COUNT(*) FROM customer WHERE c_current_addr_sk = ca_address_sk) AS customer_count
    FROM
        customer_address
    WHERE
        ca_country = 'USA'
),
Demographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        cd_credit_rating,
        cd_dep_count,
        cd_dep_employed_count,
        cd_dep_college_count
    FROM
        customer_demographics
    WHERE
        cd_purchase_estimate > 1000
),
FullReport AS (
    SELECT
        a.full_address,
        a.ca_city,
        a.ca_state,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate,
        a.customer_count
    FROM
        AddressDetails a
    JOIN
        Demographics d ON a.ca_address_sk = d.cd_demo_sk
    WHERE
        a.customer_count > 5
)
SELECT
    full_address,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    cd_purchase_estimate,
    customer_count,
    RANK() OVER (PARTITION BY ca_state ORDER BY cd_purchase_estimate DESC) AS rank_within_state
FROM
    FullReport
ORDER BY
    ca_state, rank_within_state;
