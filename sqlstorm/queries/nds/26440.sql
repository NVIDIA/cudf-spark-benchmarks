
WITH ProcessedAddresses AS (
    SELECT
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' 
                    THEN CONCAT(' Suite ', TRIM(ca_suite_number)) END) AS full_address,
        UPPER(TRIM(ca_city)) AS processed_city,
        LOWER(TRIM(ca_state)) AS processed_state,
        SUBSTRING(TRIM(ca_zip), 1, 5) AS zip_prefix
    FROM customer_address
),
FilteredDemographics AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        CASE 
            WHEN cd_marital_status = 'M' THEN 'Married'
            WHEN cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        REPLACE(UPPER(TRIM(cd_education_status)), ' ', '_') AS education_status,
        cd_purchase_estimate * 1.1 AS adjusted_purchase_estimate
    FROM customer_demographics
    WHERE cd_purchase_estimate > 1000
),
FinalBenchmark AS (
    SELECT
        pa.full_address,
        pd.marital_status,
        pd.education_status,
        COUNT(*) OVER (PARTITION BY pd.education_status) AS education_count,
        COUNT(*) OVER (PARTITION BY pd.marital_status) AS marital_count,
        SUM(pd.adjusted_purchase_estimate) OVER () AS total_adjusted_estimate
    FROM ProcessedAddresses pa
    JOIN FilteredDemographics pd ON pa.ca_address_sk = pd.cd_demo_sk
)
SELECT 
    full_address,
    marital_status,
    education_status,
    education_count,
    marital_count,
    total_adjusted_estimate
FROM FinalBenchmark
ORDER BY total_adjusted_estimate DESC
LIMIT 100;
