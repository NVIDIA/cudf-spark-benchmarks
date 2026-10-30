
WITH  sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
), ranked_items AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS total_sales_rank
    FROM sales_summary ss
    WHERE ss.sales_rank = 1
), customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS customer_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), store_data AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        AVG(ss.ss_net_paid) AS avg_transaction_value
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    si.s_store_name,
    si.total_transactions,
    si.avg_transaction_value,
    CASE 
        WHEN ci.cd_purchase_estimate IS NULL THEN 'Unknown'
        WHEN ci.cd_purchase_estimate < 1000 THEN 'Low Value Customer'
        ELSE 'High Value Customer'
    END AS customer_value_category,
    CASE 
        WHEN ci.cd_marital_status IS NULL OR ci.cd_gender IS NULL THEN 'Not Specified'
        ELSE CONCAT(ci.cd_marital_status, '-', ci.cd_gender)
    END AS marital_gender_code
FROM customer_details ci
JOIN store_data si ON ci.c_customer_sk = si.s_store_sk
WHERE si.total_transactions > 10
  AND ci.customer_rank <= 5
UNION ALL
SELECT 
    NULL AS c_customer_sk,
    NULL AS c_first_name,
    NULL AS c_last_name,
    'Total' AS cd_gender,
    si.s_store_name,
    SUM(si.total_transactions) AS total_transactions,
    AVG(si.avg_transaction_value) AS avg_transaction_value,
    'Aggregate' AS customer_value_category,
    NULL AS marital_gender_code
FROM store_data si
GROUP BY si.s_store_name
ORDER BY cd_gender, total_transactions DESC;
