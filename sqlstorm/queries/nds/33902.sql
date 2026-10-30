
WITH  SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerRanked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
SalesSummary AS (
    SELECT 
        a.item_id,
        COALESCE(s.total_quantity, 0) AS total_sales_quantity,
        COALESCE(s.total_sales, 0) AS total_sales_value,
        i.avg_inventory
    FROM (
        SELECT 
            i_item_id AS item_id, 
            i_item_sk
        FROM item
    ) AS a
    LEFT JOIN SalesCTE AS s ON a.i_item_sk = s.ws_item_sk
    LEFT JOIN InventoryStatus AS i ON a.i_item_sk = i.inv_item_sk
)
SELECT 
    ss.item_id,
    ss.total_sales_quantity,
    ss.total_sales_value,
    ss.avg_inventory,
    cr.c_first_name,
    cr.c_last_name,
    cr.gender_rank
FROM SalesSummary AS ss
JOIN CustomerRanked AS cr ON ss.total_sales_quantity > cr.gender_rank
WHERE ss.avg_inventory IS NOT NULL
ORDER BY ss.total_sales_value DESC
LIMIT 100;
