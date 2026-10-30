
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(cr_order_number) AS total_returns
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_returns, 0) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY COALESCE(cr.total_return_amount, 0) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE 
        cd.cd_credit_rating IN ('Excellent', 'Good')
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        AVG(i.i_current_price) AS avg_item_price,
        SUM(i.i_current_price) AS total_inventory_value
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    ws.w_warehouse_id,
    ws.avg_item_price,
    ws.total_inventory_value,
    CASE 
        WHEN tc.total_return_amount > 1000 THEN 'High Return'
        WHEN tc.total_return_amount BETWEEN 500 AND 1000 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    TopCustomers tc
JOIN 
    WarehouseStats ws ON tc.rn <= 5
WHERE 
    ws.avg_item_price IS NOT NULL
ORDER BY 
    tc.total_return_amount DESC, tc.c_last_name ASC;
