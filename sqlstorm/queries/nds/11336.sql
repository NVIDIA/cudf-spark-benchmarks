
WITH SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
ReturnsData AS (
    SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns 
    GROUP BY 
        wr_item_sk
)
SELECT 
    sd.ws_item_sk, 
    sd.total_quantity, 
    sd.total_net_profit, 
    COALESCE(rd.total_return_quantity, 0) AS total_return_quantity, 
    COALESCE(rd.total_return_amt, 0) AS total_return_amt
FROM 
    SalesData sd
LEFT JOIN 
    ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk
ORDER BY 
    sd.total_net_profit DESC
LIMIT 100;
