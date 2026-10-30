
WITH CustomerReturns AS (
    SELECT 
        wr_returned_date_sk, 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT wr_order_number) AS return_count
    FROM web_returns
    GROUP BY wr_returned_date_sk, wr_item_sk
),
StoreSales AS (
    SELECT 
        ss_sold_date_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_sold_quantity,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
),
ReturnAnalysis AS (
    SELECT 
        cr.wr_item_sk,
        cs.total_sold_quantity,
        cr.total_return_quantity,
        cr.return_count,
        CASE 
            WHEN cs.total_sold_quantity IS NULL THEN 0 
            ELSE (CAST(cr.total_return_quantity AS DECIMAL) / cs.total_sold_quantity) * 100 
        END AS return_rate,
        cs.total_net_profit
    FROM CustomerReturns cr
    LEFT JOIN StoreSales cs ON cr.wr_item_sk = cs.ss_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ra.total_sold_quantity AS quantity_sold,
    ra.total_return_quantity AS quantity_returned,
    ra.return_count AS number_of_returns,
    ra.return_rate,
    ra.total_net_profit
FROM item i
JOIN ReturnAnalysis ra ON i.i_item_sk = ra.wr_item_sk
WHERE 
    ra.return_rate > 10
ORDER BY 
    ra.return_rate DESC, ra.total_net_profit DESC
LIMIT 100;
