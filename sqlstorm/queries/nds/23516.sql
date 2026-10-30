
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS unique_returns
    FROM store_returns
    GROUP BY sr_returned_date_sk, sr_item_sk
),
ItemSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_sold_quantity,
        SUM(ws_sales_price) AS total_sales_amount,
        AVG(ws_net_profit) AS average_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk > 500  
    GROUP BY ws_sold_date_sk, ws_item_sk
),
ProfitMargins AS (
    SELECT 
        ir.ws_item_sk AS item_sk,
        ir.total_sales_amount,
        ir.total_sold_quantity,
        COALESCE(cr.total_returned_quantity, 0) AS total_returned_quantity,
        (ir.total_sales_amount - (COALESCE(cr.total_returned_quantity, 0) * 10.00)) / NULLIF(ir.total_sold_quantity - COALESCE(cr.total_returned_quantity, 0), 0) AS profit_margin
    FROM ItemSales ir
    LEFT JOIN CustomerReturns cr ON ir.ws_item_sk = cr.sr_item_sk AND ir.ws_sold_date_sk = cr.sr_returned_date_sk
),
RankedMargins AS (
    SELECT 
        pm.item_sk,
        pm.profit_margin,
        ROW_NUMBER() OVER (ORDER BY pm.profit_margin DESC) AS profit_rank,
        COUNT(*) OVER () AS total_items
    FROM ProfitMargins pm
    WHERE pm.profit_margin IS NOT NULL
)
SELECT 
    rm.item_sk,
    rm.profit_margin,
    (rm.total_items - rm.profit_rank + 1) AS remaining_items_better_than,
    (SELECT AVG(profit_margin) FROM RankedMargins) AS average_profit_margin
FROM RankedMargins rm
WHERE rm.profit_margin > (SELECT AVG(profit_margin) FROM RankedMargins) OR 
      rm.profit_margin IS NULL
ORDER BY rm.profit_margin DESC
LIMIT 10;
