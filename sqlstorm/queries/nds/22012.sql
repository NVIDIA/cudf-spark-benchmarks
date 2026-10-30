
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM store_returns
    GROUP BY sr_item_sk
),
WebReturnsSummary AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS web_return_count,
        SUM(wr_return_amt) AS total_web_return_amt,
        AVG(wr_return_quantity) AS avg_web_return_quantity
    FROM web_returns 
    GROUP BY wr_item_sk
),
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(*) AS sales_count,
        AVG(ws_net_profit) AS avg_profit
    FROM web_sales 
    GROUP BY ws_item_sk
),
CombinedReturns AS (
    SELECT 
        R1.sr_item_sk,
        R1.total_return_quantity AS store_return_quantity,
        R2.web_return_count,
        R2.total_web_return_amt,
        S.total_sales,
        S.total_profit,
        CASE 
            WHEN S.sales_count > 0 THEN S.avg_profit / NULLIF(S.total_sales, 0)
            ELSE NULL
        END AS profit_ratio,
        COALESCE(R1.total_return_amt, 0) + COALESCE(R2.total_web_return_amt, 0) AS combined_return_amt
    FROM RankedReturns R1
    FULL OUTER JOIN WebReturnsSummary R2 ON R1.sr_item_sk = R2.wr_item_sk
    FULL OUTER JOIN SalesData S ON COALESCE(R1.sr_item_sk, R2.wr_item_sk) = S.ws_item_sk
)
SELECT 
    C.sr_item_sk AS rc_item_sk,
    C.store_return_quantity,
    C.web_return_count,
    C.combined_return_amt,
    C.total_sales,
    C.total_profit,
    CASE
        WHEN C.combined_return_amt = 0 THEN 'No returns'
        WHEN C.combined_return_amt > 0 AND C.total_sales > 0 THEN 'Profitable returns'
        ELSE 'Loss on returns'
    END AS return_analysis,
    D.d_year,
    D.d_month_seq
FROM CombinedReturns C
JOIN date_dim D ON D.d_date_sk = (
    SELECT MAX(d_date_sk) 
    FROM date_dim 
    WHERE d_date <= DATE '2002-10-01'
)
WHERE C.profit_ratio IS NOT NULL
AND (C.combined_return_amt > 1000 OR (C.store_return_quantity IS NULL AND C.web_return_count > 5))
ORDER BY C.total_profit DESC, C.combined_return_amt DESC;
