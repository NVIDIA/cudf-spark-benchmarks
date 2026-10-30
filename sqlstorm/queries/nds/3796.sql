
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
),
InventoryStats AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(*) AS inventory_records
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returned,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk IN (SELECT d.d_date_sk 
                                    FROM date_dim d 
                                    WHERE d.d_year = 2023)
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    COALESCE(ws.rank, 0) AS sales_rank,
    inv.inv_item_sk,
    COALESCE(inv.total_quantity_on_hand, 0) AS quantity_on_hand,
    COALESCE(cr.total_returned, 0) AS total_returned,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COALESCE(ws.ws_net_profit, 0) AS net_profit
FROM 
    RankedSales ws
FULL OUTER JOIN 
    InventoryStats inv ON ws.ws_item_sk = inv.inv_item_sk
FULL OUTER JOIN 
    CustomerReturns cr ON inv.inv_item_sk = cr.sr_item_sk
WHERE 
    (ws.rank IS NOT NULL OR inv.inv_item_sk IS NOT NULL OR cr.sr_item_sk IS NOT NULL)
ORDER BY 
    net_profit DESC
LIMIT 100;
