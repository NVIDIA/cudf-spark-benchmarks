WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS item_rank
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
TopReturnedItems AS (
    SELECT 
        sr_item_sk,
        total_returned,
        total_return_amt
    FROM 
        RankedReturns
    WHERE 
        item_rank <= 10
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sold,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(SR.total_returned, 0) AS total_returned,
    COALESCE(SR.total_return_amt, 0) AS total_return_amt,
    COALESCE(SD.total_sold, 0) AS total_sold,
    COALESCE(SD.total_profit, 0) AS total_profit,
    (COALESCE(SR.total_returned, 0) * 100.0 / NULLIF(SD.total_sold, 0)) AS return_rate
FROM 
    item i
LEFT JOIN 
    TopReturnedItems SR ON i.i_item_sk = SR.sr_item_sk
LEFT JOIN 
    SalesData SD ON i.i_item_sk = SD.ws_item_sk
WHERE
    i.i_rec_start_date <= cast('2002-10-01' as date) AND (i.i_rec_end_date >= cast('2002-10-01' as date) OR i.i_rec_end_date IS NULL)
ORDER BY 
    return_rate DESC;