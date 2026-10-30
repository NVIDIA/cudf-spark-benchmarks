
WITH  potential_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, cd_gender, cd_marital_status, cd_purchase_estimate, 
           ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_purchase_estimate DESC) AS rank
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE (cd_purchase_estimate IS NOT NULL OR c_first_name IS NOT NULL)
    AND cd_marital_status IN ('M', 'S')
    AND (c_birth_month = 4 OR cd_gender = 'F')
), 
date_sales AS (
    SELECT d_year, SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales 
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    WHERE d_year BETWEEN 2017 AND 2022
    GROUP BY d_year
), 
average_sales AS (
    SELECT d_year, AVG(total_sales) AS average_yearly_sales
    FROM date_sales
    GROUP BY d_year
),
filtered_returns AS (
    SELECT sr_store_sk, SUM(sr_return_quantity) AS total_returns, SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM store_returns 
    WHERE sr_return_quantity > 0 
    GROUP BY sr_store_sk
),
enhanced_address_info AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 
           COALESCE(ca_state, 'Unknown State') AS validated_state
    FROM customer_address 
    WHERE ca_city IS NOT NULL
),
final_metrics AS (
    SELECT p.cd_gender AS gender, p.cd_marital_status AS marital_status,
           (SELECT AVG(total_returns) 
            FROM filtered_returns) AS average_returns,
           (SELECT COUNT(*) 
            FROM potential_customers) AS potential_customers_count,
           a.validated_state
    FROM potential_customers p
    JOIN enhanced_address_info a ON p.c_customer_sk = a.ca_address_sk
    WHERE p.rank <= 10 
)
SELECT year_data.d_year, year_data.average_yearly_sales, f.validated_state, f.average_returns, f.potential_customers_count
FROM average_sales year_data
CROSS JOIN (
    SELECT MIN(validated_state) AS validated_state,
           AVG(average_returns) AS average_returns, 
           COUNT(DISTINCT potential_customers_count) AS potential_customers_count
    FROM final_metrics
) f
ORDER BY year_data.d_year DESC
LIMIT 5;
