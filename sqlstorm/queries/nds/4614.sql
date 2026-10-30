
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighReturnCustomers AS (
    SELECT 
        cr.sr_customer_sk,
        cr.total_returns,
        cr.total_return_amount,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        CustomerReturns cr
    JOIN 
        customer_demographics cd ON cr.sr_customer_sk = cd.cd_demo_sk
    WHERE 
        cr.total_returns > 5
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        ROW_NUMBER() OVER (ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS inventory_rank
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    hrc.total_returns,
    hrc.total_return_amount,
    hrc.cd_gender,
    hrc.cd_marital_status,
    inv.total_inventory,
    CASE 
        WHEN inv.total_inventory IS NULL THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS inventory_status
FROM 
    HighReturnCustomers hrc
LEFT JOIN 
    customer cu ON hrc.sr_customer_sk = cu.c_customer_sk
LEFT JOIN 
    InventoryStatus inv ON hrc.sr_customer_sk = inv.inv_item_sk
WHERE 
    hrc.cd_credit_rating = 'High'
ORDER BY 
    hrc.total_return_amount DESC
LIMIT 10;
