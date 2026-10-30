
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 0
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
HighProfitItems AS (
    SELECT 
        s.ws_item_sk,
        s.total_net_profit,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(r.total_returns, 0) > 0 THEN 
                (s.total_net_profit / COALESCE(r.total_returns, 1))
            ELSE 
                s.total_net_profit
        END AS profit_per_return
    FROM 
        SalesCTE s 
    LEFT JOIN 
        CustomerReturns r ON s.ws_item_sk = r.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    h.total_net_profit,
    h.total_returns,
    h.total_return_amount,
    h.profit_per_return,
    ROW_NUMBER() OVER (ORDER BY h.total_net_profit DESC) AS item_rank
FROM 
    HighProfitItems h
JOIN 
    item i ON h.ws_item_sk = i.i_item_sk
WHERE 
    h.total_net_profit > 1000
ORDER BY 
    h.total_net_profit DESC
LIMIT 10;
