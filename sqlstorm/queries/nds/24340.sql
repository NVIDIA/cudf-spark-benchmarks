
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_month_seq IN (8, 9))
),
HighValueReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IS NOT NULL
    GROUP BY 
        wr.wr_item_sk
    HAVING 
        SUM(wr.wr_return_amt) > 500
),
SalesWithReturns AS (
    SELECT 
        r.ws_item_sk,
        r.ws_order_number,
        r.ws_sold_date_sk,
        r.ws_net_profit,
        COALESCE(hvr.total_return_amt, 0) AS total_return_amt,
        COALESCE(hvr.return_count, 0) AS return_count,
        r.profit_rank
    FROM 
        RankedSales r
    LEFT JOIN 
        HighValueReturns hvr ON r.ws_item_sk = hvr.wr_item_sk
)
SELECT 
    COALESCE(NULLIF(SUM(s.ws_net_profit), 0), 1) / NULLIF(SUM(s.total_return_amt), 0) AS profitability_ratio,
    COUNT(DISTINCT s.ws_item_sk) AS distinct_items_sold
FROM 
    SalesWithReturns s
WHERE 
    s.profit_rank <= 5
GROUP BY 
    s.ws_sold_date_sk
HAVING 
    COALESCE(NULLIF(SUM(s.ws_net_profit), 0), 1) / NULLIF(SUM(s.total_return_amt), 0) > 0
ORDER BY 
    profitability_ratio DESC;
