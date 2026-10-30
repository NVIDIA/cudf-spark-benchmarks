
WITH  address_patterns AS (
    SELECT ca_address_id, 
           ca_street_name, 
           ca_city, 
           ca_state, 
           TRIM(SUBSTRING(ca_street_name FROM POSITION(' ' IN ca_street_name) + 1 FOR CHAR_LENGTH(ca_street_name))) AS street_suffix 
    FROM customer_address
), 
demographic_analysis AS (
    SELECT cd_gender, 
           COUNT(DISTINCT c_customer_sk) AS customer_count, 
           AVG(cd_purchase_estimate) AS avg_purchase_estimate 
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY cd_gender
),
address_aggregates AS (
    SELECT ca_state, 
           COUNT(DISTINCT ca_address_id) AS unique_address_count, 
           STRING_AGG(DISTINCT street_suffix, ', ') AS street_suffixes 
    FROM address_patterns 
    GROUP BY ca_state
)
SELECT a.ca_state, 
       a.unique_address_count, 
       a.street_suffixes, 
       d.cd_gender, 
       d.customer_count, 
       d.avg_purchase_estimate 
FROM address_aggregates a 
JOIN demographic_analysis d ON a.ca_state = d.cd_gender
ORDER BY a.ca_state, d.cd_gender;
