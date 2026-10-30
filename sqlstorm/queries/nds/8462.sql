
WITH sales_data AS (
    SELECT
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY
        c.c_customer_id
),
sales_comparison AS (
    SELECT
        sd.c_customer_id,
        sd.total_web_sales,
        sd.total_catalog_sales,
        sd.total_store_sales,
        CASE
            WHEN sd.total_web_sales > sd.total_catalog_sales AND sd.total_web_sales > sd.total_store_sales THEN 'Web'
            WHEN sd.total_catalog_sales > sd.total_web_sales AND sd.total_catalog_sales > sd.total_store_sales THEN 'Catalog'
            ELSE 'Store'
        END AS preferred_channel
    FROM
        sales_data sd
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sc.total_web_sales,
    sc.total_catalog_sales,
    sc.total_store_sales,
    sc.preferred_channel
FROM
    customer c
JOIN
    sales_comparison sc ON c.c_customer_id = sc.c_customer_id
WHERE
    sc.total_web_sales > 1000 AND
    sc.total_catalog_sales = 0
ORDER BY
    sc.total_web_sales DESC
LIMIT 100;
