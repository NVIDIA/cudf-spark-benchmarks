
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = '2023-01-01'
        ) AND (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_date = '2023-12-31'
        )
    GROUP BY 
        ws.ws_item_sk
), HighProfitItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        i.i_item_id,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY sd.total_profit DESC) AS item_rank
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.rn = 1
), CustomerReturns AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        COUNT(DISTINCT cr.cr_order_number) AS return_count
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
)

SELECT 
    hpi.item_rank,
    hpi.i_item_id,
    hpi.i_item_desc,
    hpi.total_quantity,
    hpi.total_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.return_count, 0) AS return_count,
    CASE 
        WHEN hpi.total_profit > 500 THEN 'High Profit'
        WHEN hpi.total_profit <= 500 AND hpi.total_profit > 100 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    HighProfitItems hpi
LEFT JOIN 
    CustomerReturns cr ON hpi.ws_item_sk = cr.cr_item_sk
WHERE 
    hpi.item_rank <= 10
ORDER BY 
    hpi.total_profit DESC;
