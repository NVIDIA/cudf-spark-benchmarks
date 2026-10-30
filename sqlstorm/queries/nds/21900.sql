
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS quantity_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Unknown'
        END AS marital_status,
        COALESCE(hd.hd_vehicle_count, 0) AS vehicle_count,
        COALESCE(hd.hd_dep_count, 0) AS dependent_count
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON hd.hd_demo_sk = cd.cd_demo_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
),
TopItemsByWarehouse AS (
    SELECT 
        ws_warehouse_sk, 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY ws_warehouse_sk ORDER BY SUM(ws_quantity) DESC) AS item_rank
    FROM web_sales
    GROUP BY ws_warehouse_sk, ws_item_sk
)
SELECT 
    cm.c_customer_sk,
    cm.c_first_name,
    cm.c_last_name,
    cm.marital_status,
    cm.vehicle_count,
    cm.dependent_count,
    ris.total_quantity,
    ris.total_net_profit,
    ti.total_quantity AS warehouse_quantity,
    ti.ws_warehouse_sk
FROM CustomerMetrics AS cm
LEFT JOIN RankedSales AS ris ON ris.ws_item_sk IN (
    SELECT ws_item_sk 
    FROM TopItemsByWarehouse 
    WHERE item_rank <= 5
)
LEFT JOIN TopItemsByWarehouse AS ti ON ti.ws_item_sk = ris.ws_item_sk
WHERE cm.vehicle_count IS NOT NULL 
AND cm.dependent_count IS NOT NULL 
AND EXISTS (
    SELECT 1 
    FROM store_sales AS ss 
    WHERE ss.ss_item_sk = ris.ws_item_sk 
    AND ss.ss_sales_price > 0
)
ORDER BY cm.marital_status, ris.total_net_profit DESC;
