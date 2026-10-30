
WITH  sales_data AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        sd.total_sales,
        sd.order_count,
        sd.sales_rank
    FROM customer c
    INNER JOIN sales_data sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    WHERE sd.total_sales > (SELECT AVG(total_sales) FROM sales_data)
),
customer_info AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.c_email_address,
        cs.total_sales,
        cs.order_count
    FROM customer_sales cs
    LEFT JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.c_email_address,
    ci.ca_city,
    ci.ca_state,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ci.order_count,
    ROUND(ci.total_sales, 2) AS total_sales,
    CASE 
        WHEN ci.cd_dep_count IS NULL THEN 'N/A'
        ELSE CAST(ci.cd_dep_count AS STRING)
    END AS dep_count,
    ROW_NUMBER() OVER (PARTITION BY ci.ca_state ORDER BY ci.total_sales DESC) AS row_per_state
FROM customer_info ci
WHERE ci.total_sales IS NOT NULL
ORDER BY ci.ca_state, total_sales DESC;
