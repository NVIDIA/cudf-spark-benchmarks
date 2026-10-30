
WITH demographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate,
        LEAD(cd_purchase_estimate) OVER (PARTITION BY cd_gender ORDER BY cd_demo_sk) AS next_purchase_estimate
    FROM
        customer_demographics
    WHERE
        cd_purchase_estimate IS NOT NULL
),
high_value_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_purchase_estimate,
        CASE
            WHEN d.cd_purchase_estimate > 1000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS customer_segment
    FROM
        customer AS c
    JOIN
        demographics AS d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE
        d.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM demographics)
        OR (d.cd_gender = 'F' AND d.cd_purchase_estimate IS NOT NULL)
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(1) AS customer_count,
        SUM(CASE WHEN hv.customer_segment = 'High Value' THEN 1 ELSE 0 END) AS high_value_customers_count
    FROM
        customer_address AS ca
    LEFT JOIN
        customer AS c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN
        high_value_customers AS hv ON c.c_customer_sk = hv.c_customer_sk
    GROUP BY
        ca.ca_address_sk, ca.ca_city
)
SELECT
    ai.ca_address_sk,
    ai.ca_city,
    ai.customer_count,
    ai.high_value_customers_count,
    COALESCE(ai.high_value_customers_count * 1.0 / NULLIF(ai.customer_count, 0), 0) AS high_value_ratio,
    CASE
        WHEN ai.customer_count > 10 THEN 'Busy Area'
        ELSE 'Quiet Area'
    END AS area_type
FROM
    address_info AS ai
WHERE
    ai.customer_count > 0
    AND ai.ca_city IS NOT NULL
ORDER BY
    high_value_ratio DESC, ai.ca_city;
