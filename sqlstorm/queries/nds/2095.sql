
WITH CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
), 
SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(SD.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(CR.return_count, 0) AS return_count,
    COALESCE(CR.total_return_amount, 0) AS total_return_amount,
    SD.total_net_profit,
    CASE 
        WHEN COALESCE(SD.total_quantity_sold, 0) = 0 THEN NULL 
        ELSE (COALESCE(SD.total_net_profit, 0) / COALESCE(SD.total_quantity_sold, 1)) 
    END AS net_profit_per_unit
FROM 
    item i
LEFT JOIN 
    SalesData SD ON i.i_item_sk = SD.ws_item_sk
LEFT JOIN 
    CustomerReturns CR ON i.i_item_sk = CR.sr_item_sk
WHERE 
    (COALESCE(SD.total_net_profit, 0) > 100 OR COALESCE(CR.total_return_amount, 0) > 100)
ORDER BY 
    net_profit_per_unit DESC
LIMIT 10;
