
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(ws.ws_order_number) AS web_sales_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        SUM(COALESCE(ws.ws_quantity, 0)) AS total_items_sold,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS rn
    FROM
        customer AS c
    LEFT JOIN web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_salutation IS NOT NULL
        AND (c.c_birth_day IS NOT NULL OR c.c_birth_month IS NOT NULL OR c.c_birth_year IS NOT NULL)
        AND (c.c_first_name ILIKE '%' || 'John' || '%' OR c.c_last_name ILIKE '%' || 'Doe' || '%')
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
DemographicSummary AS (
    SELECT
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        COUNT(DISTINCT CASE WHEN cd.cd_marital_status = 'M' THEN c.c_customer_sk END) AS married_count
    FROM
        customer_demographics AS cd
    JOIN customer AS c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY
        cd.cd_gender
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.web_sales_count,
    COALESCE(cs.total_web_sales, 0) AS adjusted_total_web_sales,
    COALESCE(cs.total_items_sold, 0) AS total_items_sold,
    ds.cd_gender,
    ds.avg_purchase_estimate,
    ds.customer_count,
    ds.married_count
FROM
    CustomerSales AS cs
FULL OUTER JOIN DemographicSummary AS ds ON cs.web_sales_count > 3
WHERE
    (cs.rn <= 10 OR ds.customer_count IS NOT NULL)
    AND (ds.cd_gender IS NULL OR ds.cd_gender = 'F')
ORDER BY
    COALESCE(cs.total_web_sales, 0) DESC,
    ds.avg_purchase_estimate ASC
LIMIT 50;
