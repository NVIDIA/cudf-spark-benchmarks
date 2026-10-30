
WITH sales_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
demographic_summary AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
),
ranked_sales AS (
    SELECT 
        s.c_customer_sk,
        s.total_sales,
        s.order_count,
        ds.customer_count,
        ds.cd_gender,
        ds.cd_marital_status
    FROM sales_summary s
    LEFT JOIN demographic_summary ds ON s.c_customer_sk = ds.cd_demo_sk
    WHERE s.total_sales > 1000 AND ds.customer_count > 5
),
final_report AS (
    SELECT
        r.cd_gender,
        r.cd_marital_status,
        AVG(r.total_sales) AS avg_sales,
        MAX(r.order_count) AS max_orders,
        COUNT(DISTINCT r.c_customer_sk) AS unique_customers
    FROM ranked_sales r
    GROUP BY r.cd_gender, r.cd_marital_status
)
SELECT 
    fr.cd_gender,
    fr.cd_marital_status,
    fr.avg_sales,
    fr.max_orders,
    COALESCE(fr.unique_customers, 0) AS customer_count
FROM final_report fr
FULL OUTER JOIN (
    SELECT DISTINCT cd.cd_gender, cd.cd_marital_status
    FROM customer_demographics cd
) demo ON fr.cd_gender = demo.cd_gender AND fr.cd_marital_status = demo.cd_marital_status
ORDER BY fr.cd_gender, fr.cd_marital_status;
