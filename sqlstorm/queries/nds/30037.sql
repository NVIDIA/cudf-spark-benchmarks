
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY ws_sold_date_sk, ws_item_sk
),
TopSales AS (
    SELECT
        ws_item_sk,
        total_quantity,
        total_profit
    FROM SalesCTE
    WHERE profit_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    ts.total_quantity,
    ts.total_profit,
    CASE 
        WHEN ts.total_profit IS NULL THEN 'No Profit'
        ELSE CONCAT('Profit: ', CAST(ts.total_profit AS STRING))
    END AS profit_statement,
    COALESCE((SELECT 
                    AVG(total_quantity) 
                FROM TopSales 
                WHERE total_profit > 0), 0) AS avg_positive_quantity
FROM item i
LEFT JOIN TopSales ts
ON i.i_item_sk = ts.ws_item_sk
WHERE i.i_current_price > 10
ORDER BY ts.total_profit DESC;
