
WITH EnhancedCustomerInfo AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(CAST(EXTRACT(YEAR FROM TIMESTAMP '2002-10-01 12:34:56') AS STRING), 'Unknown') AS current_year,
        CASE
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High Buyer'
            WHEN cd.cd_purchase_estimate BETWEEN 500 AND 1000 THEN 'Medium Buyer'
            ELSE 'Low Buyer'
        END AS buyer_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'TX', 'NY')
),
StringBenchmark AS (
    SELECT 
        full_name,
        LENGTH(full_name) AS name_length,
        LENGTH(cd_gender) AS gender_length,
        LENGTH(cd_marital_status) AS marital_length,
        LENGTH(cd_education_status) AS education_length,
        LENGTH(ca_city) AS city_length,
        LENGTH(ca_state) AS state_length,
        buyer_category
    FROM 
        EnhancedCustomerInfo
),
AggregatedResults AS (
    SELECT 
        buyer_category,
        AVG(name_length) AS avg_name_length,
        SUM(gender_length) AS total_gender_length,
        SUM(marital_length) AS total_marital_length,
        SUM(education_length) AS total_education_length,
        AVG(city_length) AS avg_city_length,
        AVG(state_length) AS avg_state_length
    FROM 
        StringBenchmark
    GROUP BY 
        buyer_category
)
SELECT 
    buyer_category,
    avg_name_length,
    total_gender_length,
    total_marital_length,
    total_education_length,
    avg_city_length,
    avg_state_length
FROM 
    AggregatedResults
ORDER BY 
    buyer_category ASC;
