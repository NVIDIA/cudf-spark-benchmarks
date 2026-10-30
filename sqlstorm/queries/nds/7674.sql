
WITH sales_summary AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        SUM(store_sales.ss_net_paid) AS total_sales,
        COUNT(DISTINCT store_sales.ss_ticket_number) AS transaction_count,
        AVG(store_sales.ss_net_paid) AS average_transaction_value
    FROM store_sales
    JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
    JOIN date_dim ON store_sales.ss_sold_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_year = 2023
    GROUP BY customer.c_customer_id, customer.c_first_name, customer.c_last_name
),
demographics_summary AS (
    SELECT 
        customer_demographics.cd_demo_sk,
        SUM(sales_summary.total_sales) AS total_sales,
        COUNT(sales_summary.transaction_count) AS transaction_count
    FROM sales_summary
    JOIN customer ON sales_summary.c_customer_id = customer.c_customer_id
    JOIN customer_demographics ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    GROUP BY customer_demographics.cd_demo_sk
),
income_summary AS (
    SELECT 
        household_demographics.hd_income_band_sk,
        SUM(demographics_summary.total_sales) AS total_sales,
        AVG(demographics_summary.transaction_count) AS average_transaction_count
    FROM demographics_summary
    JOIN household_demographics ON demographics_summary.cd_demo_sk = household_demographics.hd_demo_sk
    GROUP BY household_demographics.hd_income_band_sk
)
SELECT 
    income_band.ib_lower_bound, 
    income_band.ib_upper_bound,
    income_summary.total_sales,
    income_summary.average_transaction_count
FROM income_summary
JOIN income_band ON income_summary.hd_income_band_sk = income_band.ib_income_band_sk
ORDER BY income_band.ib_lower_bound;
