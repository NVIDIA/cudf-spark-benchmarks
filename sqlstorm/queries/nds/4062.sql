
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(MAX(cs.cs_sales_price), 0) AS max_catalog_price,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_catalog_returns
    FROM item i
    LEFT JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
),
ranked_sales AS (
    SELECT 
        ss.ws_item_sk,
        ss.total_quantity,
        ss.total_net_profit,
        ss.order_count,
        ss.avg_net_paid,
        id.i_item_id,
        id.i_product_name,
        RANK() OVER (ORDER BY ss.total_net_profit DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY id.i_item_id ORDER BY ss.order_count DESC) AS item_order_rank
    FROM sales_summary ss
    JOIN item_details id ON ss.ws_item_sk = id.i_item_sk
)
SELECT 
    rs.i_item_id,
    rs.i_product_name,
    rs.total_quantity,
    rs.total_net_profit,
    rs.order_count,
    rs.avg_net_paid,
    rs.profit_rank,
    id.max_catalog_price,
    id.total_returns,
    id.total_catalog_returns
FROM ranked_sales rs
JOIN item_details id ON rs.i_item_id = id.i_item_id
WHERE rs.profit_rank <= 10
  AND id.total_returns > 0
ORDER BY rs.profit_rank, rs.total_net_profit DESC
LIMIT 50;
