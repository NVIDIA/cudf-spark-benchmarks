
WITH sales_summary AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq IN (1, 2, 3)
    GROUP BY
        ws.ws_item_sk
),
returns_summary AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM
        web_returns wr
    JOIN 
        date_dim dd ON wr.wr_returned_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY
        wr.wr_item_sk
),
inventory_status AS (
    SELECT
        inv.inv_item_sk,
        MAX(inv.inv_quantity_on_hand) AS max_quantity_on_hand
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
)
SELECT
    it.i_item_id,
    it.i_item_desc,
    COALESCE(ss.total_quantity, 0) AS web_sales_quantity,
    COALESCE(ss.total_net_profit, 0) AS web_sales_net_profit,
    COALESCE(rs.total_return_quantity, 0) AS web_return_quantity,
    COALESCE(rs.total_return_loss, 0) AS web_return_loss,
    iv.max_quantity_on_hand
FROM
    item it
LEFT JOIN
    sales_summary ss ON it.i_item_sk = ss.ws_item_sk
LEFT JOIN
    returns_summary rs ON it.i_item_sk = rs.wr_item_sk
LEFT JOIN
    inventory_status iv ON it.i_item_sk = iv.inv_item_sk
WHERE
    (COALESCE(ss.total_quantity, 0) - COALESCE(rs.total_return_quantity, 0)) > iv.max_quantity_on_hand
ORDER BY
    web_sales_net_profit DESC
LIMIT 10;
