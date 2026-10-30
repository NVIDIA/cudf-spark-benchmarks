
WITH customer_stats AS (
    SELECT
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        SUM(COALESCE(cd_purchase_estimate, 0)) AS total_purchase_estimate,
        AVG(COALESCE(cd_dep_count, 0)) AS avg_dependents,
        AVG(COALESCE(cd_dep_employed_count, 0)) AS avg_employed_dependents,
        AVG(COALESCE(cd_dep_college_count, 0)) AS avg_college_dependents
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd_gender,
        cd_marital_status
),
sales_summary AS (
    SELECT
        ws.ws_web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales AS ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ws.ws_web_site_sk
)
SELECT
    cs.cd_gender,
    cs.cd_marital_status,
    COALESCE(ss.total_net_profit, 0) AS total_net_profit,
    cs.total_customers,
    cs.total_purchase_estimate,
    cs.avg_dependents,
    cs.avg_employed_dependents,
    cs.avg_college_dependents
FROM
    customer_stats AS cs
LEFT JOIN
    sales_summary AS ss ON ss.ws_web_site_sk = (SELECT web_site_sk FROM web_site WHERE web_site_id = 'WS0001')
ORDER BY
    cs.cd_gender,
    cs.cd_marital_status;
