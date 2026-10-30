
WITH  sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
), 
customer_returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
), 
top_items AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        ss.total_net_profit,
        COALESCE(cr.total_returns, 0) AS returns,
        COALESCE(cr.total_return_amount, 0) AS return_amount,
        ss.order_count,
        ss.rank
    FROM sales_summary ss
    JOIN item ON item.i_item_sk = ss.ws_item_sk
    LEFT JOIN customer_returns cr ON cr.sr_item_sk = ss.ws_item_sk
    WHERE ss.rank <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.total_net_profit AS profit,
    ti.returns AS total_returns,
    ti.return_amount,
    (ti.total_net_profit - ti.return_amount) AS net_positive_profit
FROM top_items ti
ORDER BY net_positive_profit DESC
LIMIT 5;
