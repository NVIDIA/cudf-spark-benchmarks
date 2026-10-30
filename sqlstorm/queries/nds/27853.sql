
WITH CustomerInfo AS (
    SELECT c.c_customer_id, 
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
           d.d_date AS first_purchase_date,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_education_status,
           COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential,
           COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
StringBenchmark AS (
    SELECT full_name,
           first_purchase_date,
           LENGTH(full_name) AS name_length,
           LENGTH(CONCAT(cd_gender, cd_marital_status, cd_education_status)) AS demographic_info_length,
           COUNT(*) OVER() AS total_customers
    FROM CustomerInfo
),
RankedCustomers AS (
    SELECT full_name, 
           first_purchase_date,
           name_length,
           demographic_info_length,
           ROW_NUMBER() OVER (ORDER BY name_length DESC, demographic_info_length DESC) AS rank
    FROM StringBenchmark
)
SELECT full_name, 
       first_purchase_date, 
       name_length, 
       demographic_info_length, 
       rank
FROM RankedCustomers
WHERE rank <= 100;
