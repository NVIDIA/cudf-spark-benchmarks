
WITH concatenated_addresses AS (
    SELECT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_suite_number, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
           ca_county
    FROM customer_address
), demographic_analysis AS (
    SELECT cd_gender, cd_marital_status, cd_education_status, COUNT(DISTINCT c_customer_sk) AS customer_count,
           AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender, cd_marital_status, cd_education_status
), enriched_data AS (
    SELECT a.full_address, d.cd_gender, d.cd_marital_status, d.cd_education_status, d.customer_count, d.avg_purchase_estimate
    FROM concatenated_addresses a
    JOIN demographic_analysis d ON a.ca_county LIKE CONCAT('%', d.cd_gender, '%')
)
SELECT ed.full_address, ed.cd_gender, ed.cd_marital_status, ed.customer_count, ed.avg_purchase_estimate
FROM enriched_data ed
WHERE ed.customer_count > 10
ORDER BY ed.avg_purchase_estimate DESC
LIMIT 100;
