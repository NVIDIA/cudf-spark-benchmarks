
WITH  SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    HAVING 
        SUM(ws_quantity) > 10
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        cs_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) AS rn
    FROM 
        catalog_sales
    WHERE 
        cs_item_sk IN (SELECT ws_item_sk FROM web_sales)
    GROUP BY 
        cs_item_sk, cs_sold_date_sk
    HAVING 
        SUM(cs_quantity) > 5
),
ItemInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS quantity_on_hand
    FROM 
        inventory
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv_item_sk
),
Returns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalSummary AS (
    SELECT 
        i.i_item_id,
        COALESCE(s.total_quantity, 0) AS total_sales_quantity,
        COALESCE(iih.quantity_on_hand, 0) AS quantity_on_hand,
        COALESCE(s.total_profit, 0) AS total_sales_profit,
        COALESCE(r.total_returns, 0) AS total_returns
    FROM 
        item i
    LEFT JOIN (
        SELECT ws_item_sk, SUM(total_quantity) AS total_quantity, SUM(total_profit) AS total_profit 
        FROM SalesCTE 
        WHERE rn = 1 
        GROUP BY ws_item_sk
    ) s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN ItemInventory iih ON i.i_item_sk = iih.inv_item_sk
    LEFT JOIN Returns r ON i.i_item_sk = r.sr_item_sk
)
SELECT 
    f.i_item_id,
    f.total_sales_quantity,
    f.quantity_on_hand,
    f.total_sales_profit,
    f.total_returns,
    CASE 
        WHEN f.quantity_on_hand IS NULL THEN 'No Inventory'
        WHEN f.total_sales_quantity = 0 THEN 'No Sales'
        ELSE 'Available'
    END AS inventory_status
FROM 
    FinalSummary f
WHERE 
    f.total_sales_quantity > 10 OR f.total_returns > 0
ORDER BY 
    f.total_sales_profit DESC;
