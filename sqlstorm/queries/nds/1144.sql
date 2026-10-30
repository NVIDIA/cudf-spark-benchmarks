
WITH InventoryData AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
SalesData AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
ReturnData AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
FinalAnalysis AS (
    SELECT
        COALESCE(i.inv_item_sk, s.ws_item_sk) AS i_item_sk,
        COALESCE(i.total_quantity, 0) AS available_stock,
        COALESCE(s.total_sales_quantity, 0) AS sold_quantity,
        COALESCE(r.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(s.total_net_profit, 0) AS net_profit,
        (COALESCE(s.total_sales_quantity, 0) - COALESCE(r.total_returned_quantity, 0)) AS effective_sales,
        (COALESCE(s.total_net_profit, 0) - COALESCE(r.total_return_amt, 0)) AS effective_net_profit
    FROM 
        InventoryData i
    FULL OUTER JOIN 
        SalesData s ON i.inv_item_sk = s.ws_item_sk
    FULL OUTER JOIN 
        ReturnData r ON s.ws_item_sk = r.wr_item_sk OR i.inv_item_sk = r.wr_item_sk
)
SELECT 
    f.i_item_sk,
    f.available_stock,
    f.sold_quantity,
    f.returned_quantity,
    f.net_profit,
    f.effective_sales,
    f.effective_net_profit,
    CONCAT('Item_', f.i_item_sk) AS item_label,
    CASE 
        WHEN f.effective_sales > 100 THEN 'High Demand'
        WHEN f.effective_sales BETWEEN 50 AND 100 THEN 'Moderate Demand'
        ELSE 'Low Demand'
    END AS demand_level
FROM 
    FinalAnalysis f
WHERE 
    f.effective_net_profit IS NOT NULL 
    AND f.effective_sales > 10
ORDER BY 
    f.effective_net_profit DESC
LIMIT 50;
