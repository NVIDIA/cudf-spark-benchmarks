
WITH RecursiveAddress AS (
    SELECT ca_address_sk, CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address, 
           ca_city, ca_state, ca_zip, ca_country
    FROM customer_address
),
TransformedDemographics AS (
    SELECT cd_demo_sk, 
           CASE 
               WHEN cd_gender = 'M' THEN 'Male'
               WHEN cd_gender = 'F' THEN 'Female'
               ELSE 'Other'
           END AS gender,
           UPPER(cd_marital_status) AS marital_status,
           REGEXP_REPLACE(cd_education_status, '[^A-Za-z ]', '') AS clean_education,
           CONCAT(cd_dep_count, ' dependents') AS dependents 
    FROM customer_demographics
),
DateFiltered AS (
    SELECT d_date_sk, d_year, d_month_seq, d_day_name
    FROM date_dim
    WHERE d_date >= '2023-01-01' AND d_date <= '2023-12-31'
),
FinalReport AS (
    SELECT a.full_address, a.ca_city, a.ca_state, a.ca_zip, a.ca_country,
           d.d_year, d.d_month_seq, d.d_day_name,
           demographics.gender, demographics.marital_status, demographics.clean_education, demographics.dependents
    FROM RecursiveAddress a
    JOIN DateFiltered d ON d.d_date_sk IN (SELECT DISTINCT sr_returned_date_sk FROM store_returns WHERE sr_returned_date_sk IS NOT NULL)
    JOIN TransformedDemographics demographics ON demographics.cd_demo_sk IN (SELECT DISTINCT sr_cdemo_sk FROM store_returns WHERE sr_cdemo_sk IS NOT NULL)
)
SELECT full_address, ca_city, ca_state, ca_zip, ca_country, d_year, d_month_seq, d_day_name, 
       COUNT(*) AS total_records
FROM FinalReport
GROUP BY full_address, ca_city, ca_state, ca_zip, ca_country, d_year, d_month_seq, d_day_name
ORDER BY d_year DESC, d_month_seq ASC, ca_city;
