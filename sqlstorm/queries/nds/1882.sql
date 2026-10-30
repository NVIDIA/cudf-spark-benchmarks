
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c.c_customer_sk
),
additional_info AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM
        customer_demographics cd
    JOIN customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
)
SELECT
    cs.c_customer_sk,
    cs.total_web_sales,
    cs.total_catalog_sales,
    cs.total_web_orders,
    cs.total_catalog_orders,
    ai.cd_gender,
    ai.cd_marital_status,
    ai.ca_country,
    CASE 
        WHEN cs.total_web_sales IS NULL THEN 'No Web Sales'
        WHEN cs.total_catalog_sales IS NULL THEN 'No Catalog Sales'
        ELSE 'Both Sales'
    END AS sales_status
FROM
    customer_sales cs
LEFT JOIN additional_info ai ON cs.c_customer_sk = ai.cd_demo_sk
WHERE
    ai.rn <= 5
    OR (ai.cd_gender = 'M' AND cs.total_web_sales > 1000)
ORDER BY 
    total_web_sales DESC NULLS LAST,
    total_catalog_sales DESC NULLS LAST;
