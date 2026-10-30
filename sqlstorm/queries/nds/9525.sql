
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(CASE WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_ext_sales_price ELSE 0 END) AS total_web_sales,
        SUM(CASE WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_ext_sales_price ELSE 0 END) AS total_catalog_sales,
        SUM(CASE WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_ext_sales_price ELSE 0 END) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer AS c
    LEFT JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        EXISTS (SELECT 1 FROM store WHERE s_store_sk = ss.ss_store_sk)
        OR EXISTS (SELECT 1 FROM web_site WHERE web_site_sk = ws.ws_web_site_sk)
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
avg_sales AS (
    SELECT
        cd_gender,
        cd_marital_status,
        cd_education_status,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM
        sales_summary
    GROUP BY
        cd_gender, cd_marital_status, cd_education_status
)
SELECT
    gender.cd_gender,
    gender.cd_marital_status,
    gender.cd_education_status,
    avg_sales.avg_web_sales,
    avg_sales.avg_catalog_sales,
    avg_sales.avg_store_sales
FROM
    (SELECT DISTINCT cd_gender, cd_marital_status, cd_education_status FROM sales_summary) AS gender
JOIN
    avg_sales ON gender.cd_gender = avg_sales.cd_gender
    AND gender.cd_marital_status = avg_sales.cd_marital_status
    AND gender.cd_education_status = avg_sales.cd_education_status
ORDER BY
    gender.cd_gender, gender.cd_marital_status, gender.cd_education_status;
