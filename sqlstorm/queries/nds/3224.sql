
WITH sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS item_rank
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE
        i.i_current_price IS NOT NULL
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ranked_sales AS (
    SELECT
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid,
        sd.item_rank,
        i.i_item_desc,
        i.i_brand,
        CASE 
            WHEN i.i_current_price > 0 THEN (sd.total_net_paid / i.i_current_price) 
            ELSE NULL 
        END AS price_to_sales_ratio
    FROM
        sales_data sd
    JOIN
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE
        sd.item_rank <= 10
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    r.ws_sold_date_sk,
    r.ws_item_sk,
    r.i_item_desc,
    r.total_quantity,
    r.total_net_paid,
    r.price_to_sales_ratio,
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status
FROM
    ranked_sales r
LEFT JOIN
    customer_info ci ON r.ws_item_sk = ci.c_current_cdemo_sk
WHERE
    (ci.cd_gender IS NULL OR ci.cd_gender = 'F')
    AND (ci.cd_marital_status IS NULL OR ci.cd_marital_status = 'S')
ORDER BY
    r.total_net_paid DESC,
    r.total_quantity DESC
LIMIT 50;
