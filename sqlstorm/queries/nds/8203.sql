
WITH aggregated_sales AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        AVG(ss_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ss_store_sk
),
customer_demographics_summary AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        SUM(cd_purchase_estimate) AS total_estimate
    FROM 
        customer_demographics
    JOIN 
        customer ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_demo_sk, cd_gender, cd_marital_status
),
store_info AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_city,
        s_state
    FROM 
        store
)
SELECT 
    si.s_store_name,
    si.s_city,
    si.s_state,
    cs.cd_gender,
    cs.cd_marital_status,
    sa.total_sales,
    sa.avg_sales_price,
    sa.transaction_count,
    cs.customer_count,
    cs.total_estimate
FROM 
    aggregated_sales sa
JOIN 
    store_info si ON sa.ss_store_sk = si.s_store_sk
JOIN 
    customer_demographics_summary cs ON cs.customer_count > 0
ORDER BY 
    si.s_store_name, cs.cd_gender, cs.cd_marital_status;
