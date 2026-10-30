
WITH customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year >= 1980
    GROUP BY
        c.c_customer_sk
),
warehouse_sales AS (
    SELECT
        w.w_warehouse_sk,
        SUM(ws.ws_quantity) AS warehouse_quantity,
        SUM(ws.ws_net_paid) AS warehouse_net_paid
    FROM
        warehouse w
    JOIN
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    WHERE
        w.w_state = 'CA'
    GROUP BY
        w.w_warehouse_sk
),
demographics_summary AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer_demographics cd
    JOIN
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender
)
SELECT
    cs.c_customer_sk,
    cs.total_quantity,
    cs.total_net_paid,
    ws.warehouse_quantity,
    ws.warehouse_net_paid,
    ds.cd_demo_sk,
    ds.cd_gender,
    ds.avg_purchase_estimate,
    ds.customer_count
FROM
    customer_sales cs
JOIN
    warehouse_sales ws ON cs.c_customer_sk % 10 = ws.w_warehouse_sk % 10
JOIN
    demographics_summary ds ON cs.c_customer_sk % 5 = ds.cd_demo_sk % 5
WHERE
    cs.total_quantity > 50
    AND ws.warehouse_quantity < 1000
ORDER BY
    cs.total_net_paid DESC
LIMIT 50;
