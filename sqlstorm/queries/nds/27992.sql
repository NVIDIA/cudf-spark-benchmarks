WITH address_summary AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(DISTINCT ca_address_id) AS unique_addresses,
        COUNT(DISTINCT ca_street_name) AS unique_streets
    FROM customer_address
    GROUP BY ca_city, ca_state
),
customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
detailed_address AS (
    SELECT
        a.ca_address_id,
        a.ca_street_name,
        a.ca_street_type,
        a.ca_city,
        a.ca_state,
        a.ca_zip,
        a.ca_country,
        ca.unique_addresses,
        ca.unique_streets
    FROM customer_address a
    JOIN address_summary ca ON a.ca_city = ca.ca_city AND a.ca_state = ca.ca_state
),
education_insights AS (
    SELECT
        ci.cd_education_status,
        COUNT(ci.c_customer_id) AS total_customers,
        AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_info ci
    GROUP BY ci.cd_education_status
)
SELECT
    da.ca_city,
    da.ca_state,
    da.ca_zip,
    da.unique_addresses,
    da.unique_streets,
    ei.cd_education_status,
    ei.total_customers,
    ei.avg_purchase_estimate
FROM detailed_address da
JOIN education_insights ei ON da.ca_state IN (
        SELECT ca.ca_state
        FROM address_summary ca
        WHERE ca.unique_addresses > 10
    )
WHERE da.ca_zip LIKE '9%' 
ORDER BY da.ca_city, da.ca_state, ei.cd_education_status;