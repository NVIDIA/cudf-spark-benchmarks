
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales,
        SUM(ss.ss_net_profit) AS total_store_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
customer_ranked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_web_sales DESC) AS web_sales_rank,
        ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        ROW_NUMBER() OVER (PARTITION BY hd_income_band_sk ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM customer_sales
)
SELECT 
    cr.c_customer_sk,
    cr.cd_gender,
    cr.cd_marital_status,
    cr.hd_income_band_sk,
    cr.total_web_sales,
    cr.total_catalog_sales,
    cr.total_store_sales,
    cr.web_order_count,
    cr.catalog_order_count,
    cr.store_order_count
FROM customer_ranked cr
WHERE cr.web_sales_rank <= 10 OR cr.catalog_sales_rank <= 10 OR cr.store_sales_rank <= 10
ORDER BY cr.hd_income_band_sk, cr.total_web_sales DESC, cr.total_catalog_sales DESC, cr.total_store_sales DESC;
