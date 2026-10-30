
WITH TotalReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM store_returns
    GROUP BY sr_item_sk
),
HighReturnItems AS (
    SELECT
        tr.sr_item_sk,
        tr.total_returned_quantity,
        tr.total_return_amt,
        tr.total_return_tax,
        ROW_NUMBER() OVER (ORDER BY tr.total_return_amt DESC) AS rn
    FROM TotalReturns tr
    WHERE tr.total_returned_quantity > 5
),
HighReturnPromotions AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        p.p_promo_name,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS promo_rank
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE ws.ws_item_sk IN (SELECT sr_item_sk FROM HighReturnItems WHERE rn <= 10)
)
SELECT 
    item.i_item_id,
    item.i_item_desc,
    hi.total_returned_quantity,
    hi.total_return_amt,
    hi.total_return_tax,
    grp.p_promo_name,
    AVG(grp.ws_net_profit) AS avg_net_profit,
    COUNT(DISTINCT grp.ws_order_number) AS total_orders
FROM HighReturnItems hi
JOIN item ON hi.sr_item_sk = item.i_item_sk
LEFT JOIN HighReturnPromotions grp ON hi.sr_item_sk = grp.ws_item_sk AND grp.promo_rank = 1
GROUP BY 
    item.i_item_id,
    item.i_item_desc,
    hi.total_returned_quantity,
    hi.total_return_amt,
    hi.total_return_tax,
    grp.p_promo_name
HAVING AVG(grp.ws_net_profit) > 0 OR grp.p_promo_name IS NULL
ORDER BY hi.total_returned_quantity DESC, avg_net_profit DESC
LIMIT 50;
