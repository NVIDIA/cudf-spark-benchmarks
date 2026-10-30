
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
),
ReturnStatistics AS (
    SELECT 
        c.c_customer_sk,
        MAX(cr.total_return_amount) AS max_return_amount,
        AVG(cr.total_return_amount) AS avg_return_amount
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON cr.sr_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COALESCE(rs.max_return_amount, 0) AS max_returning,
    COALESCE(rs.avg_return_amount, 0) AS avg_returning,
    wi.total_quantity_on_hand,
    CASE 
        WHEN wi.total_quantity_on_hand IS NULL THEN 'No Inventory'
        ELSE 'Available Inventory'
    END AS inventory_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    ReturnStatistics rs ON hvc.c_customer_sk = rs.c_customer_sk
LEFT JOIN 
    WarehouseInventory wi ON wi.inv_warehouse_sk = (
        SELECT 
            w.w_warehouse_sk
        FROM 
            warehouse w
        ORDER BY 
            w.w_warehouse_sq_ft DESC 
        LIMIT 1
    )
WHERE 
    hvc.rank <= 5
ORDER BY 
    hvc.cd_gender, hvc.cd_purchase_estimate DESC;
