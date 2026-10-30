
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_net_paid_inc_tax), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid_inc_tax), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid_inc_tax), 0) AS total_store_sales
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_store_sales,
    (cs.total_web_sales + cs.total_catalog_sales + cs.total_store_sales) AS total_sales,
    CASE 
        WHEN (ci.gender_rank <= 10 AND cs.total_web_sales > 1000) THEN 'High Value'
        ELSE 'Standard Value'
    END AS customer_value
FROM
    customer_info ci
JOIN customer_sales cs ON ci.c_customer_sk = cs.c_customer_sk
WHERE
    (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL)
    AND (cs.total_web_sales > 0 OR cs.total_catalog_sales > 0 OR cs.total_store_sales > 0)
ORDER BY total_sales DESC
LIMIT 100;
