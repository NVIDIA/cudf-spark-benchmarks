
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state
    FROM
        customer_address
),
address_count AS (
    SELECT 
        city,
        state,
        COUNT(*) AS address_count
    FROM
        processed_addresses
    GROUP BY
        city,
        state
),
demographics_summary AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents
    FROM
        customer_demographics
    GROUP BY 
        cd_gender,
        cd_marital_status
),
final_report AS (
    SELECT 
        a.city,
        a.state,
        a.address_count,
        d.cd_gender,
        d.cd_marital_status,
        d.avg_purchase_estimate,
        d.total_dependents
    FROM
        address_count a
    JOIN
        demographics_summary d ON a.city = d.cd_gender
    ORDER BY 
        a.address_count DESC, 
        d.avg_purchase_estimate DESC
)
SELECT 
    city,
    state,
    address_count,
    cd_gender,
    cd_marital_status,
    avg_purchase_estimate,
    total_dependents
FROM 
    final_report
WHERE 
    address_count > 10
AND 
    avg_purchase_estimate > 1000
LIMIT 50;
