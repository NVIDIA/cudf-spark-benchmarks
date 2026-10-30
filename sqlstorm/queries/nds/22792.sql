
WITH demographic_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(cd_dep_count) AS avg_dep_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM customer_demographics
    LEFT JOIN customer ON customer.c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status, cd_purchase_estimate
),
sales_analysis AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
returns_analysis AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
),
combined_data AS (
    SELECT 
        ds.cd_gender,
        ds.customer_count,
        ds.total_purchase_estimate,
        sa.total_quantity,
        sa.total_sales,
        sa.total_discount,
        rs.return_count,
        rs.total_return_amt
    FROM demographic_summary ds
    LEFT JOIN sales_analysis sa ON ds.cd_demo_sk = sa.ws_bill_customer_sk
    LEFT JOIN returns_analysis rs ON ds.cd_demo_sk = rs.sr_customer_sk
)
SELECT 
    cd_gender,
    SUM(total_sales) AS overall_sales,
    SUM(total_discount) AS total_discounts,
    COALESCE(SUM(customer_count), 0) AS total_customers,
    COALESCE(SUM(return_count), 0) AS total_returns,
    COUNT(CASE WHEN return_count IS NULL THEN 1 END) AS customers_without_returns
FROM combined_data
GROUP BY cd_gender
ORDER BY overall_sales DESC
LIMIT 10;
