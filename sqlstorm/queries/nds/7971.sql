
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
), demographic_stats AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk
), final_report AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        ds.avg_purchase_estimate,
        ds.customer_count
    FROM customer_sales cs
    JOIN demographic_stats ds ON cs.c_customer_sk = ds.cd_demo_sk
    WHERE cs.total_web_sales > 1000 OR cs.total_catalog_sales > 1000 OR cs.total_store_sales > 1000
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    fr.total_web_sales,
    fr.total_catalog_sales,
    fr.total_store_sales,
    fr.avg_purchase_estimate,
    fr.customer_count
FROM final_report fr
JOIN customer c ON fr.c_customer_sk = c.c_customer_sk
ORDER BY total_web_sales DESC, total_catalog_sales DESC, total_store_sales DESC
LIMIT 50;
