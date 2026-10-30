
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
WarehouseStock AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items
    FROM 
        inventory inv
    WHERE 
        inv.inv_quantity_on_hand > 0
    GROUP BY 
        inv.inv_warehouse_sk
),
StoreSalesData AS (
    SELECT 
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_store_sk
)
SELECT 
    ws.w_warehouse_id,
    ws.w_warehouse_name,
    ws.w_city,
    ws.w_state,
    COALESCE(ssd.total_sales, 0) AS total_store_sales,
    COALESCE(wsi.total_quantity, 0) AS total_inventory,
    (SELECT COUNT(*) FROM CustomerStats WHERE purchase_rank <= 5 AND cd_gender = 'F') AS top_female_customers,
    (SELECT COUNT(*) FROM CustomerStats WHERE purchase_rank <= 5 AND cd_gender = 'M') AS top_male_customers
FROM 
    warehouse ws
LEFT JOIN 
    WarehouseStock wsi ON ws.w_warehouse_sk = wsi.inv_warehouse_sk
LEFT JOIN 
    StoreSalesData ssd ON ws.w_warehouse_sk = ssd.ss_store_sk
WHERE 
    ws.w_state IN ('CA', 'NY')
ORDER BY 
    total_store_sales DESC NULLS LAST;
