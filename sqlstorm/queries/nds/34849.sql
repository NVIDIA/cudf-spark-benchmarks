
WITH  sales_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_year, c_current_cdemo_sk,
           ROW_NUMBER() OVER (PARTITION BY c_current_cdemo_sk ORDER BY c_birth_year DESC) AS rn
    FROM customer
    WHERE c_birth_year IS NOT NULL
),
store_sales_summary AS (
    SELECT ss_store_sk, SUM(ss_ext_sales_price) AS total_sales,
           COUNT(ss_ticket_number) AS total_transactions
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 21000 AND 21030
    GROUP BY ss_store_sk
),
top_stores AS (
    SELECT s_store_sk, s_store_name
    FROM store
    WHERE s_store_sk IN (SELECT ss_store_sk FROM store_sales_summary WHERE total_sales > 500000)
),
max_income_customers AS (
    SELECT MAX(cd_purchase_estimate) as max_purchase_estimate
    FROM customer_demographics
    WHERE cd_credit_rating IS NOT NULL
),
customer_insights AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           cd.cd_credit_rating, cd.cd_purchase_estimate,
           s.total_sales AS store_sales,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_credit_rating ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer ch
    JOIN customer_demographics cd ON ch.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales_summary s ON ch.c_customer_sk = s.ss_store_sk
    WHERE cd.cd_purchase_estimate > (SELECT max_purchase_estimate FROM max_income_customers)
),
final_summary AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name,
           ci.cd_credit_rating, ci.store_sales, 
           CASE 
               WHEN ci.store_sales IS NULL THEN 'No Sales'
               WHEN ci.store_sales >= 1000000 THEN 'High Roller'
               ELSE 'Regular Customer'
           END AS customer_type,
           th.s_store_name
    FROM customer_insights ci
    JOIN top_stores th ON ci.store_sales IS NOT NULL
    WHERE ci.rank <= 5
)
SELECT DISTINCT f.c_customer_sk, f.c_first_name, f.c_last_name, 
                f.store_sales, f.customer_type, f.s_store_name
FROM final_summary f
ORDER BY f.store_sales DESC;
