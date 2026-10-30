
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
),
MostReturnedItems AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returns
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn = 1
    GROUP BY 
        rr.sr_item_sk
    HAVING 
        SUM(rr.sr_return_quantity) > 10
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(w.ws_sold_date_sk, 0) AS last_sold_date,
        COALESCE(w.ws_net_profit, 0) AS net_profit,
        i.i_item_sk
    FROM 
        item i
    LEFT JOIN 
        web_sales w ON i.i_item_sk = w.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
),
FinalResult AS (
    SELECT 
        id.i_item_id,
        id.i_item_desc,
        id.i_current_price,
        id.last_sold_date,
        id.net_profit,
        CASE 
            WHEN id.net_profit < 0 THEN 'Loss'
            WHEN id.net_profit = 0 THEN 'Break Even'
            ELSE 'Profit'
        END AS financial_status,
        CASE 
            WHEN EXISTS (SELECT 1 FROM MostReturnedItems mri WHERE mri.sr_item_sk = id.i_item_sk) 
            THEN 'High Return Rate'
            ELSE 'Normal Return Rate'
        END AS return_status
    FROM 
        ItemDetails id
)
SELECT 
    fr.*,
    CONCAT(fr.i_item_desc, ' - ', fr.financial_status) AS item_status,
    NULLIF(fr.last_sold_date, 0) AS last_sold_date_real
FROM 
    FinalResult fr
ORDER BY 
    fr.net_profit DESC, fr.i_current_price ASC
LIMIT 50 OFFSET 0;
