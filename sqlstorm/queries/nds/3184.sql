
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profitability_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
),

TopProducts AS (
    SELECT 
        sd.ws_item_sk,
        SUM(sd.ws_quantity) AS total_quantity,
        SUM(sd.ws_net_profit) AS total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.profitability_rank <= 5
    GROUP BY 
        sd.ws_item_sk
),

CustomerReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)

SELECT 
    i.i_item_id,
    COALESCE(tp.total_quantity, 0) AS total_sold,
    COALESCE(tp.total_net_profit, 0) AS total_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    CASE 
        WHEN COALESCE(tp.total_net_profit, 0) > 0 
        THEN ROUND(COALESCE(cr.total_return_amt, 0) / COALESCE(tp.total_net_profit, 0) * 100, 2)
        ELSE 0 
    END AS return_percentage
FROM 
    item i
LEFT JOIN 
    TopProducts tp ON i.i_item_sk = tp.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    return_percentage DESC
LIMIT 10;
