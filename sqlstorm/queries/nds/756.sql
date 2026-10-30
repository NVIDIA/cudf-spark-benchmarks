
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
ReturnsData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    JOIN 
        date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        wr.wr_item_sk
),
TopProfitableItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        sd.total_profit - COALESCE(rd.total_returns, 0) * 10 AS net_profit_after_returns
    FROM 
        SalesData sd
    LEFT JOIN 
        ReturnsData rd ON sd.ws_item_sk = rd.wr_item_sk
    WHERE 
        sd.rank_profit <= 10
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    tpi.total_quantity,
    tpi.total_profit,
    tpi.total_returns,
    tpi.net_profit_after_returns
FROM 
    TopProfitableItems tpi
JOIN 
    item ti ON tpi.ws_item_sk = ti.i_item_sk
ORDER BY 
    tpi.net_profit_after_returns DESC;
