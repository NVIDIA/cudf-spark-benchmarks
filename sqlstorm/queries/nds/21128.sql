
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_ticket_number,
        DENSE_RANK() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rnk
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
),
HighValueReturns AS (
    SELECT 
        r1.sr_item_sk, 
        SUM(r1.sr_return_amt) AS total_return_amt,
        COUNT(r1.sr_ticket_number) AS return_count
    FROM RankedReturns r1
    JOIN RankedReturns r2 ON r1.sr_item_sk = r2.sr_item_sk
        AND r1.rnk = r2.rnk
    WHERE r1.sr_return_quantity > 5
    GROUP BY r1.sr_item_sk
),
InventoryDetails AS (
    SELECT 
        i.inv_item_sk, 
        SUM(i.inv_quantity_on_hand) AS total_on_hand,
        COALESCE(SUM(i.inv_quantity_on_hand) / NULLIF(SUM(CASE WHEN r.total_return_amt > 100 THEN 1 END), 0), 0) AS return_ratio
    FROM inventory i
    LEFT JOIN HighValueReturns r ON i.inv_item_sk = r.sr_item_sk
    GROUP BY i.inv_item_sk
),
FinalSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_net_profit) AS total_profit,
        (CASE 
            WHEN SUM(ws.ws_quantity) > 100 THEN 'High'
            WHEN SUM(ws.ws_quantity) BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low' 
        END) AS sales_category
    FROM web_sales ws
    JOIN InventoryDetails id ON ws.ws_item_sk = id.inv_item_sk
    WHERE id.total_on_hand > 0 AND id.return_ratio < 1
    GROUP BY ws.ws_item_sk
)
SELECT 
    fs.ws_item_sk,
    fs.total_sold,
    fs.total_profit,
    fs.sales_category,
    COALESCE(id.return_ratio, 0) AS effective_return_ratio
FROM FinalSales fs
LEFT JOIN InventoryDetails id ON fs.ws_item_sk = id.inv_item_sk
ORDER BY fs.total_profit DESC, fs.total_sold DESC;
