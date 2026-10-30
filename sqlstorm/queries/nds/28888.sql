
WITH customer_fullnames AS (
    SELECT
        c.c_customer_sk,
        CONCAT(TRIM(c.c_first_name), ' ', TRIM(c.c_last_name)) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COALESCE(NULLIF(cd.cd_credit_rating, ''), 'Unknown') AS credit_rating
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
city_profiles AS (
    SELECT
        ca.ca_city,
        COUNT(DISTINCT cf.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_address ca
    JOIN
        customer_fullnames cf ON ca.ca_address_sk = cf.c_customer_sk
    JOIN
        customer_demographics cd ON cf.c_customer_sk = cd.cd_demo_sk
    GROUP BY
        ca.ca_city
),
top_cities AS (
    SELECT
        ca.ca_city,
        cp.customer_count,
        cp.avg_purchase_estimate,
        DENSE_RANK() OVER (ORDER BY cp.avg_purchase_estimate DESC) AS city_rank
    FROM
        city_profiles cp
    JOIN 
        customer_address ca ON cp.ca_city = ca.ca_city
)
SELECT 
    rc.city_rank,
    rc.ca_city AS city,
    rc.customer_count,
    rc.avg_purchase_estimate,
    CASE
        WHEN rc.customer_count > 100 THEN 'High Density'
        WHEN rc.customer_count BETWEEN 50 AND 100 THEN 'Medium Density'
        ELSE 'Low Density'
    END AS density_category
FROM 
    top_cities rc
WHERE 
    rc.city_rank <= 10
ORDER BY 
    rc.city_rank;
