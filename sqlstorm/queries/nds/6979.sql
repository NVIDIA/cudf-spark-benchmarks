
WITH total_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales_amount
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2400 AND 2405
    GROUP BY
        ws_item_sk
),
promotional_sales AS (
    SELECT
        p.p_promo_name,
        SUM(ws.ws_quantity) AS promo_quantity,
        SUM(ws.ws_net_paid) AS promo_sales_amount
    FROM
        web_sales ws
    JOIN
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2400 AND 2405
    GROUP BY
        p.p_promo_name
),
top_items AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        cs.total_quantity,
        cs.total_sales_amount
    FROM
        customer_address ca
    JOIN
        total_sales cs ON ca.ca_address_sk = cs.ws_item_sk
    WHERE
        ca.ca_state IN ('CA', 'TX', 'NY')
    ORDER BY
        cs.total_sales_amount DESC
    LIMIT 10
)
SELECT
    ti.ca_city,
    ti.ca_state,
    ti.total_quantity,
    ti.total_sales_amount,
    ps.promo_quantity,
    ps.promo_sales_amount
FROM
    top_items ti
LEFT JOIN
    promotional_sales ps ON ti.total_quantity = ps.promo_quantity
ORDER BY
    ti.total_sales_amount DESC;
