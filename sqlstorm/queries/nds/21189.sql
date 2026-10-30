
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
CustomerReturnStats AS (
    SELECT 
        rc.c_customer_id,
        COUNT(sr.sr_ticket_number) AS store_returns_count,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_store_return_amt,
        SUM(CASE WHEN sr.sr_return_quantity IS NULL THEN 1 ELSE 0 END) AS null_return_quantity_count
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        store_returns sr ON rc.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        rc.c_customer_id
),
InventoryReport AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory
    GROUP BY 
        inv_date_sk,
        inv_item_sk
)
SELECT 
    cr.c_customer_id,
    cr.store_returns_count,
    cr.total_store_return_amt,
    cr.null_return_quantity_count,
    ir.total_quantity,
    CASE 
        WHEN ir.total_quantity < 10 THEN 'Low Inventory'
        WHEN ir.total_quantity BETWEEN 10 AND 50 THEN 'Medium Inventory'
        ELSE 'High Inventory'
    END AS inventory_status
FROM 
    CustomerReturnStats cr
JOIN 
    InventoryReport ir ON cr.store_returns_count = ir.inv_item_sk
WHERE 
    cr.store_returns_count > 0
ORDER BY 
    cr.total_store_return_amt DESC, 
    inventory_status ASC 
LIMIT 50 OFFSET 0;
