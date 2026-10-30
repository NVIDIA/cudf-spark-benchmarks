
WITH address_standardization AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type), 
               CASE WHEN ca_suite_number IS NOT NULL AND ca_suite_number <> '' THEN CONCAT(' Suite ', TRIM(ca_suite_number)) ELSE '' END) AS full_address,
        LOWER(TRIM(ca_city)) AS normalized_city,
        UPPER(TRIM(ca_state)) AS normalized_state
    FROM customer_address
), 
demographics_summary AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(DISTINCT c_customer_sk) AS customer_count, 
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    JOIN customer ON cd_demo_sk = c_current_cdemo_sk
    GROUP BY cd_gender, cd_marital_status
),
date_summary AS (
    SELECT 
        d_year, 
        d_month_seq, 
        COUNT(DISTINCT ws_order_number) AS total_sales,
        SUM(ws_sales_price) AS total_revenue
    FROM web_sales 
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY d_year, d_month_seq
) 
SELECT 
    ds.d_year,
    ds.d_month_seq,
    SUM(ds.total_sales) AS monthly_sales,
    SUM(ds.total_revenue) AS monthly_revenue,
    d.cd_gender, 
    d.cd_marital_status, 
    d.customer_count,
    d.avg_purchase_estimate,
    a.full_address
FROM date_summary ds
LEFT JOIN demographics_summary d ON ds.d_month_seq % 12 = EXTRACT(MONTH FROM DATE '2002-10-01') 
LEFT JOIN address_standardization a ON d.customer_count > 100
GROUP BY ds.d_year, ds.d_month_seq, d.cd_gender, d.cd_marital_status, d.customer_count, d.avg_purchase_estimate, a.full_address
ORDER BY ds.d_year, ds.d_month_seq;
