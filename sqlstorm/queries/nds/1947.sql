
WITH sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk
),
return_data AS (
    SELECT
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt) AS total_returned_amount
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY wr.wr_item_sk
),
combined_data AS (
    SELECT
        sd.ws_item_sk,
        COALESCE(rd.total_returns, 0) AS total_returns,
        sd.total_quantity,
        sd.total_profit
    FROM sales_data sd
    LEFT JOIN return_data rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT
    cd.ws_item_sk,
    cd.total_quantity,
    cd.total_profit,
    cd.total_returns,
    CASE 
        WHEN cd.total_returns > 0 THEN ROUND((cd.total_profit / NULLIF(cd.total_returns, 0)), 2)
        ELSE NULL
    END AS profit_per_return,
    ROW_NUMBER() OVER (ORDER BY cd.total_profit DESC) AS overall_rank
FROM combined_data cd
WHERE cd.total_quantity > 100
AND (cd.total_profit > (SELECT AVG(total_profit) FROM combined_data) OR cd.total_returns > 5)
ORDER BY cd.total_profit DESC
LIMIT 20;
