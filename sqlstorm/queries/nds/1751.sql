
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2400 AND 2410
    GROUP BY ws_item_sk
),
return_summary AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_qty,
        SUM(wr_return_amt) AS total_returned_amt
    FROM web_returns
    GROUP BY wr_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE(ss.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        COALESCE(rs.total_returned_qty, 0) AS total_returned_qty,
        COALESCE(rs.total_returned_amt, 0) AS total_returned_amt,
        (COALESCE(ss.total_net_profit, 0) - COALESCE(rs.total_returned_amt, 0)) AS net_profit_after_returns
    FROM item i
    LEFT JOIN sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    LEFT JOIN return_summary rs ON i.i_item_sk = rs.wr_item_sk
)
SELECT 
    id.i_item_sk,
    id.i_product_name,
    id.total_quantity_sold,
    id.total_net_profit,
    id.total_returned_qty,
    id.total_returned_amt,
    id.net_profit_after_returns,
    CASE 
        WHEN id.net_profit_after_returns < 0 THEN 'Loss'
        WHEN id.net_profit_after_returns = 0 THEN 'Break Even'
        ELSE 'Profit'
    END AS profit_status,
    (SELECT COUNT(*) FROM item_details WHERE total_net_profit > id.total_net_profit) AS rank_in_profit
FROM item_details id
WHERE id.net_profit_after_returns <> 0
ORDER BY id.net_profit_after_returns DESC
LIMIT 10;
