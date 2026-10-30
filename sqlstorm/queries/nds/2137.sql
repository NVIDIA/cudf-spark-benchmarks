
WITH SalesData AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 AND dd.d_moy IN (1, 2, 3)
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
),
ReturnData AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM web_returns wr
    WHERE wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY wr.wr_item_sk
),
CombinedSales AS (
    SELECT 
        s.ws_item_sk,
        COALESCE(sd.total_quantity, 0) AS web_sales_quantity,
        COALESCE(rd.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(sd.total_profit, 0) AS web_total_profit
    FROM SalesData sd
    FULL OUTER JOIN ReturnData rd ON sd.ws_item_sk = rd.wr_item_sk
    FULL OUTER JOIN web_sales s ON s.ws_item_sk = COALESCE(sd.ws_item_sk, rd.wr_item_sk)
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    cs.web_sales_quantity,
    cs.total_return_quantity,
    cs.web_total_profit,
    CASE 
        WHEN cs.web_sales_quantity > 0 THEN ROUND(((cs.web_total_profit / NULLIF(cs.web_sales_quantity, 0)) * 100), 2) 
        ELSE 0 
    END AS profit_margin_percentage
FROM CombinedSales cs
JOIN item i ON cs.ws_item_sk = i.i_item_sk
WHERE cs.web_total_profit > 0 OR cs.total_return_quantity > 0
ORDER BY profit_margin_percentage DESC
LIMIT 10;
