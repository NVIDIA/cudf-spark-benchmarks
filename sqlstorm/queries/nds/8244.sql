
WITH CustomerStats AS (
    SELECT
        cd.cd_gender,
        SUM(CASE WHEN cs.cs_item_sk IS NOT NULL THEN cs.cs_quantity ELSE 0 END) AS total_quantity_sold,
        COUNT(DISTINCT c.c_customer_sk) AS number_of_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY
        cd.cd_gender
),
DateStats AS (
    SELECT
        d.d_year,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
),
WarehouseInventory AS (
    SELECT
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        warehouse w
    JOIN
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY
        w.w_warehouse_id
)
SELECT 
    cs.cd_gender,
    cs.total_quantity_sold,
    cs.number_of_customers,
    cs.avg_purchase_estimate,
    ds.d_year,
    ds.total_web_sales,
    ds.total_web_profit,
    wi.w_warehouse_id,
    wi.total_inventory
FROM 
    CustomerStats cs
JOIN 
    DateStats ds ON cs.total_quantity_sold > 0
JOIN 
    WarehouseInventory wi ON wi.total_inventory > 100
ORDER BY 
    cs.cd_gender, ds.d_year DESC, wi.total_inventory DESC
LIMIT 1000;
