
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity IS NOT NULL
    GROUP BY sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_dep_count, 0) AS dep_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
InventoryInfo AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
WebSalesInfo AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    GROUP BY ws_item_sk
)

SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    rr.total_returns,
    ii.total_inventory,
    wsi.total_sales,
    wsi.avg_net_profit
FROM CustomerInfo ci
LEFT JOIN RankedReturns rr ON rr.rn = 1 
LEFT JOIN InventoryInfo ii ON rr.sr_item_sk = ii.inv_item_sk
LEFT JOIN WebSalesInfo wsi ON rr.sr_item_sk = wsi.ws_item_sk
WHERE 
    (ci.dep_count > 2 OR ci.cd_marital_status = 'S')
    AND (ii.total_inventory IS NOT NULL AND ii.total_inventory > 100)
    AND (wsi.total_sales IS NOT NULL AND wsi.total_sales > 5000)
ORDER BY ci.c_last_name, ci.c_first_name
LIMIT 100 OFFSET 50;
