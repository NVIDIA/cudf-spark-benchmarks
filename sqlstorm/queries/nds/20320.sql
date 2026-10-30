
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        COALESCE(cd.cd_marital_status, 'N/A') AS marital_status,
        (SELECT AVG(ws.ws_net_profit) 
         FROM web_sales ws 
         WHERE ws.ws_bill_customer_sk = c.c_customer_sk
         GROUP BY ws.ws_bill_customer_sk) AS avg_web_profit,
        (SELECT COUNT(*) 
         FROM store_sales ss 
         WHERE ss.ss_customer_sk = c.c_customer_sk) AS store_sales_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk
    HAVING SUM(inv.inv_quantity_on_hand) > 100
),
DateRange AS (
    SELECT 
        d.d_date_sk,
        MAX(d.d_date) AS max_date,
        MIN(d.d_date) AS min_date
    FROM date_dim d
    WHERE d.d_year = 2023
    GROUP BY d.d_date_sk
)
SELECT 
    cs.c_first_name || ' ' || cs.c_last_name AS customer_name,
    cs.gender,
    cs.marital_status,
    cs.avg_web_profit,
    ws.total_quantity,
    CASE 
        WHEN cs.store_sales_count > 0 THEN 
            'Active' 
        ELSE 
            'Inactive' 
    END AS customer_activity_status,
    dr.max_date,
    dr.min_date
FROM CustomerStats cs
JOIN WarehouseStats ws ON cs.c_customer_sk IS NOT NULL
CROSS JOIN DateRange dr
WHERE (cs.avg_web_profit IS NOT NULL OR cs.store_sales_count > 0)
  AND (ws.total_quantity IS NOT NULL AND ws.total_quantity > 150)
ORDER BY cs.avg_web_profit DESC
LIMIT 100;
