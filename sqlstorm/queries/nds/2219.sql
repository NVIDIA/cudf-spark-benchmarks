
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        CASE
            WHEN COALESCE(SUM(ws.ws_net_paid), 0) > 1000 THEN 'High Value'
            WHEN COALESCE(SUM(ws.ws_net_paid), 0) BETWEEN 500 AND 1000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales
    FROM
        customer_sales cs
    WHERE
        cs.customer_value = 'High Value'
),
sales_summary AS (
    SELECT
        hv.c_customer_sk,
        hv.c_first_name,
        hv.c_last_name,
        hv.total_web_sales,
        hv.total_catalog_sales,
        hv.total_store_sales,
        (hv.total_web_sales + hv.total_catalog_sales + hv.total_store_sales) AS total_sales,
        RANK() OVER (ORDER BY (hv.total_web_sales + hv.total_catalog_sales + hv.total_store_sales) DESC) AS sales_rank
    FROM
        high_value_customers hv
)
SELECT
    ss.c_customer_sk,
    ss.c_first_name,
    ss.c_last_name,
    ss.total_web_sales,
    ss.total_catalog_sales,
    ss.total_store_sales,
    ss.total_sales,
    ss.sales_rank
FROM
    sales_summary ss
JOIN
    customer_demographics cd ON ss.c_customer_sk = cd.cd_demo_sk
WHERE
    cd.cd_marital_status = 'M'
    AND cd.cd_gender = 'M'
ORDER BY
    ss.sales_rank
LIMIT 10;
