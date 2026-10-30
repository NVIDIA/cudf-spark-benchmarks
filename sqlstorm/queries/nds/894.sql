
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_item_sk, ws.ws_order_number
),
RefundedSales AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_refunds
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
ItemInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    R.total_quantity,
    R.total_sales,
    COALESCE(RF.total_refunds, 0) AS total_refunds,
    II.total_inventory,
    CASE 
        WHEN II.total_inventory > 0 THEN ROUND((R.total_sales / II.total_inventory), 2) 
        ELSE NULL 
    END AS sales_per_inventory
FROM RankedSales R
JOIN item i ON R.ws_item_sk = i.i_item_sk
LEFT JOIN RefundedSales RF ON R.ws_item_sk = RF.cr_item_sk
JOIN ItemInventory II ON R.ws_item_sk = II.inv_item_sk
WHERE R.rank_sales <= 10
ORDER BY R.total_sales DESC;
