
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales
    FROM
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY
        c.c_customer_sk
),
demographic_summary AS (
    SELECT
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT cs.c_customer_sk) AS customer_count,
        SUM(cs.total_store_sales) AS total_store_sales,
        SUM(cs.total_web_sales) AS total_web_sales,
        SUM(cs.total_catalog_sales) AS total_catalog_sales
    FROM
        customer_sales cs
    JOIN customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY
        cd.cd_gender,
        hd.hd_income_band_sk
)
SELECT
    ds.cd_gender,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ds.customer_count,
    ds.total_store_sales,
    ds.total_web_sales,
    ds.total_catalog_sales
FROM
    demographic_summary ds
JOIN income_band ib ON ds.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    ds.total_store_sales > 1000000
ORDER BY
    ds.total_store_sales DESC;
