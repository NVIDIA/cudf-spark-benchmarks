
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),

SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk > 0
    GROUP BY ws.ws_item_sk
),

ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
)

SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    id.i_item_desc,
    sd.total_quantity,
    sd.total_revenue,
    id.total_inventory,
    CASE 
        WHEN sd.total_quantity IS NULL THEN 'No Sales'
        ELSE 'Sales Present' 
    END AS sales_status,
    CASE 
        WHEN rc.rn <= 10 THEN 'Top Customers'
        ELSE 'Regular Customers' 
    END AS customer_status
FROM RankedCustomers rc
LEFT JOIN SalesData sd ON rc.c_customer_sk = sd.ws_item_sk
LEFT JOIN ItemDetails id ON sd.ws_item_sk = id.i_item_sk
WHERE id.total_inventory > 0 OR sd.total_quantity IS NOT NULL
ORDER BY rc.cd_gender, sd.total_revenue DESC
LIMIT 100;
