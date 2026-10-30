
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        AVG(ws_net_paid) AS avg_order_value,
        COUNT(ws_item_sk) AS item_count
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY ws_bill_customer_sk
),
demographics_summary AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk,
        COUNT(*) AS demographic_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
final_summary AS (
    SELECT 
        ds.ws_bill_customer_sk,
        ds.total_sales,
        ds.order_count,
        ds.avg_order_value,
        ds.item_count,
        dem.cd_gender,
        dem.cd_marital_status,
        dem.cd_education_status,
        dem.hd_income_band_sk
    FROM sales_summary ds
    LEFT JOIN demographics_summary dem ON ds.ws_bill_customer_sk = dem.c_customer_sk
)
SELECT 
    f.cd_gender,
    f.cd_marital_status,
    f.hd_income_band_sk,
    COUNT(*) AS customer_count,
    SUM(f.total_sales) AS total_sales_sum,
    AVG(f.avg_order_value) AS avg_order_value,
    AVG(f.item_count) AS avg_items_per_order
FROM final_summary f
GROUP BY f.cd_gender, f.cd_marital_status, f.hd_income_band_sk
ORDER BY total_sales_sum DESC
LIMIT 10;
