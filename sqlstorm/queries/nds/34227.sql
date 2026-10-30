
WITH  SalesCTE AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0
),
TopSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        SalesCTE
    WHERE 
        rn <= 5
    GROUP BY 
        ws_order_number, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
),
ItemInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
)

SELECT 
    cs.ws_order_number,
    cs.ws_item_sk,
    cs.total_quantity AS sold_quantity,
    cs.total_net_profit AS net_profit,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    inv.total_inventory AS current_inventory,
    CASE 
        WHEN inv.total_inventory < 50 THEN 'Low Stock' 
        WHEN inv.total_inventory BETWEEN 50 AND 100 THEN 'Moderate Stock' 
        ELSE 'High Stock' 
    END AS stock_status
FROM 
    TopSales cs
LEFT JOIN 
    CustomerReturns cr ON cs.ws_item_sk = cr.sr_item_sk
LEFT JOIN 
    ItemInventory inv ON cs.ws_item_sk = inv.inv_item_sk
WHERE 
    cs.total_net_profit > 1000
ORDER BY 
    cs.total_net_profit DESC;
