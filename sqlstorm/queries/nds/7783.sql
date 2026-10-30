
WITH aggregated_sales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales AS ws
    JOIN
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ws_item_sk
),
customer_segments AS (
    SELECT
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_purchase_estimate) AS min_purchase_estimate,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk
),
top_items AS (
    SELECT
        gs.ws_item_sk,
        gs.total_quantity,
        gs.total_sales,
        cs.customer_count,
        cs.max_purchase_estimate,
        cs.min_purchase_estimate,
        cs.avg_purchase_estimate
    FROM
        aggregated_sales AS gs
    LEFT JOIN
        customer_segments AS cs ON cs.cd_demo_sk = (
            SELECT 
                cd_demo_sk 
            FROM 
                customer_demographics 
            ORDER BY 
                cd_purchase_estimate DESC 
            LIMIT 1
        )
    ORDER BY
        gs.total_sales DESC
    LIMIT 10
)
SELECT
    i.i_item_id,
    i.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ti.customer_count,
    ti.max_purchase_estimate,
    ti.min_purchase_estimate,
    ti.avg_purchase_estimate
FROM
    item AS i
JOIN
    top_items AS ti ON i.i_item_sk = ti.ws_item_sk
WHERE
    i.i_current_price > 20.00
ORDER BY
    ti.total_sales DESC;
