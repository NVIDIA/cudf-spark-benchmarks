
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws.ws_item_sk
), 
CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY wr.wr_item_sk
), 
FinalSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit,
        COALESCE(cr.return_count, 0) AS return_count,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN cr.total_return_amt IS NULL THEN 'No Returns'
            ELSE 'With Returns'
        END AS return_status,
        sd.profit_rank
    FROM SalesData sd
    LEFT JOIN CustomerReturns cr ON sd.ws_item_sk = cr.wr_item_sk
)
SELECT 
    fs.ws_item_sk,
    fs.total_quantity,
    fs.total_net_profit,
    fs.return_count,
    fs.total_return_amt,
    fs.return_status,
    CASE 
        WHEN fs.total_net_profit > 1000 THEN 'High Profit'
        WHEN fs.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit' 
    END AS profit_category
FROM FinalSales fs
WHERE fs.profit_rank = 1 
AND (fs.return_count = 0 OR fs.return_count < 5)
ORDER BY fs.total_net_profit DESC;
