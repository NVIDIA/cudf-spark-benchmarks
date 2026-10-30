
WITH SalesData AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
NegativeReturns AS (
    SELECT 
        wr_item_sk,
        COUNT(*) AS total_returns,
        SUM(wr_net_loss) AS total_loss
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
InventoryData AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.total_quantity, 0) AS total_sold,
    COALESCE(sd.total_sales, 0.00) AS total_sales,
    COALESCE(nr.total_returns, 0) AS total_returns,
    COALESCE(nr.total_loss, 0.00) AS total_loss,
    COALESCE(id.total_quantity_on_hand, 0) AS quantity_on_hand,
    CASE 
        WHEN COALESCE(sd.total_sales, 0) > 0 THEN (COALESCE(sd.total_sales, 0) - COALESCE(nr.total_loss, 0)) / COALESCE(sd.total_sales, 0) 
        ELSE NULL 
    END AS profit_margin_percentage
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    NegativeReturns nr ON i.i_item_sk = nr.wr_item_sk
LEFT JOIN 
    InventoryData id ON i.i_item_sk = id.inv_item_sk
WHERE 
    (COALESCE(sd.total_sales, 0) > 1000 OR COALESCE(nr.total_returns, 0) > 0) 
    AND i.i_current_price IS NOT NULL
ORDER BY 
    profit_margin_percentage DESC NULLS LAST
LIMIT 100;
