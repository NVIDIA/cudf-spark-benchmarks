
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity_sold
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk IS NOT NULL
),
high_sales AS (
    SELECT
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        rs.ws_quantity,
        rs.total_quantity_sold
    FROM
        ranked_sales rs
    WHERE
        rs.price_rank = 1
    AND rs.total_quantity_sold > 100
),
store_sales_summary AS (
    SELECT
        sss.ss_item_sk,
        SUM(sss.ss_net_profit) AS total_net_profit,
        COUNT(DISTINCT sss.ss_ticket_number) AS total_sales_count,
        AVG(sss.ss_sales_price) AS avg_sales_price
    FROM
        store_sales sss
    WHERE
        sss.ss_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = DATE '2002-10-01' - INTERVAL '1 year')
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = DATE '2002-10-01')
    GROUP BY
        sss.ss_item_sk
)
SELECT
    h.ws_item_sk,
    h.ws_order_number,
    h.ws_sales_price AS high_sales_price,
    h.total_quantity_sold,
    ss.total_net_profit,
    ss.total_sales_count,
    ss.avg_sales_price
FROM
    high_sales h
LEFT JOIN
    store_sales_summary ss ON h.ws_item_sk = ss.ss_item_sk
WHERE
    ss.total_net_profit IS NOT NULL
ORDER BY
    h.total_quantity_sold DESC, h.ws_sales_price DESC
LIMIT 100;
