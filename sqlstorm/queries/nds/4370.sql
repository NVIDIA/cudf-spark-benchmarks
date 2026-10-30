
WITH RankedSales AS (
    SELECT 
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit,
        RANK() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_net_profit DESC) AS rank_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_net_paid DESC) AS row_num_paid
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),

TotalReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),

SalesReturns AS (
    SELECT 
        rs.ss_item_sk,
        rs.ss_ticket_number,
        rs.ss_net_profit,
        COALESCE(tr.total_returned, 0) AS total_returned
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns tr ON rs.ss_item_sk = tr.sr_item_sk
    WHERE 
        rs.rank_profit = 1
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    sr.ss_net_profit,
    sr.total_returned,
    (sr.ss_net_profit - (sr.total_returned * i.i_current_price)) AS adjusted_profit
FROM 
    SalesReturns sr
JOIN 
    item i ON sr.ss_item_sk = i.i_item_sk
WHERE 
    (sr.total_returned > 0 OR sr.ss_net_profit > 1000)
ORDER BY 
    adjusted_profit DESC
LIMIT 10;

